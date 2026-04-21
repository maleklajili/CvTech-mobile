// Dart imports:
import 'dart:async';
import 'dart:io';

// Package imports:
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Project imports:
import 'package:cv_tech/core/config/network_config.dart';
import 'package:cv_tech/core/utils/image_url_helper.dart';

class _CachedResponse {
  final Response<dynamic> response;
  final DateTime at;
  const _CachedResponse(this.response, this.at);
}

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// In-flight GET request de-duplication.
  /// When two widgets ask for the same GET /path?query at the same time,
  /// only one HTTP request is sent and the response is shared.
  /// Key = method + full URL + auth header fingerprint.
  final Map<String, Completer<Response<dynamic>>> _inflightGets =
      <String, Completer<Response<dynamic>>>{};

  /// Short-lived GET response cache.
  /// When two widgets ask for the same GET within [_getCacheTtl], the second
  /// call is served from memory instead of hitting the backend.
  /// Per-endpoint opt-out via `extra['dedupe'] == false`.
  /// Per-endpoint custom TTL via `extra['cacheTtlMs']`.
  final Map<String, _CachedResponse> _getCache =
      <String, _CachedResponse>{};
  static const Duration _defaultGetCacheTtl = Duration(seconds: 5);

  /// Endpoints that change often and should never be cached
  /// (auth, write confirmations, long-running generation).
  static final Set<String> _noCacheEndpoints = <String>{
    '/auth/',
    '/ai-cv/generate',
    '/ai-cv/reformulate',
    '/ai-cv/download',
    '/manual-cv/download',
    '/messages/chats', // Real-time via socket, do not double-cache
    '/notifications/unread', // Badge must be fresh
  };

  bool _isCacheable(String path) {
    for (final prefix in _noCacheEndpoints) {
      if (path.startsWith(prefix)) return false;
    }
    return true;
  }

  /// Stream that emits when session expires (401 + refresh failed).
  /// AuthBloc listens to this to force logout.
  static final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast();
  static Stream<void> get onSessionExpired => _sessionExpiredController.stream;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:9000', // Backend port from .env
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 90),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.acceptHeader: 'application/json',
        },
      ),
    );
    
    // Mettre à jour l'URL dynamiquement
    _updateBaseUrl();

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Keep base URL synchronized even after hot reload and singleton reuse.
          final latestBaseUrl = await NetworkConfig.getBackendUrl();
          if (options.baseUrl != latestBaseUrl) {
            options.baseUrl = latestBaseUrl;
            _dio.options.baseUrl = latestBaseUrl;
            ImageUrlHelper.setBaseUrl(latestBaseUrl);
            print('🌐 ApiClient request baseUrl synced: $latestBaseUrl');
          }

          // Ne pas ajouter le token pour les endpoints d'authentification
          final path = options.path;
          final isAuthEndpoint = path.startsWith('/auth/login') ||
              path.startsWith('/auth/send-otp') ||
              path.startsWith('/auth/verify-otp') ||
              path.startsWith('/auth/refreshToken') ||
              path.startsWith('/auth/forget-password');
          
          if (!isAuthEndpoint) {
            final token = await getAccessToken();
            if (token != null) {
              options.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
            }
          }

          // ─── GET deduplication ────────────────────────────────────────
          // If an identical GET is already in flight, piggy-back on it
          // instead of firing a new HTTP request. Saves 2-3x duplicate hits
          // from widgets watching the same data (current-user, friends…).
          if (options.method.toUpperCase() == 'GET' &&
              options.extra['dedupe'] != false) {
            final key = _dedupeKey(options);

            // (1) Short-TTL cache: same GET called a few seconds ago?
            if (_isCacheable(options.path)) {
              final cached = _getCache[key];
              final ttlMs = (options.extra['cacheTtlMs'] as int?) ??
                  _defaultGetCacheTtl.inMilliseconds;
              if (cached != null &&
                  DateTime.now().difference(cached.at).inMilliseconds <
                      ttlMs) {
                return handler.resolve(
                  Response<dynamic>(
                    data: cached.response.data,
                    statusCode: cached.response.statusCode,
                    statusMessage: cached.response.statusMessage,
                    headers: cached.response.headers,
                    requestOptions: options,
                    extra: cached.response.extra,
                    isRedirect: cached.response.isRedirect,
                    redirects: cached.response.redirects,
                  ),
                );
              }
            }

            // (2) In-flight dedup: another identical GET currently running?
            final pending = _inflightGets[key];
            if (pending != null) {
              try {
                final shared = await pending.future;
                // Clone the shared response so each caller gets its own
                // RequestOptions reference (some callers mutate it).
                return handler.resolve(
                  Response<dynamic>(
                    data: shared.data,
                    statusCode: shared.statusCode,
                    statusMessage: shared.statusMessage,
                    headers: shared.headers,
                    requestOptions: options,
                    extra: shared.extra,
                    isRedirect: shared.isRedirect,
                    redirects: shared.redirects,
                  ),
                );
              } catch (e) {
                // Pending request failed — let this one proceed fresh.
              }
            }
            final completer = Completer<Response<dynamic>>();
            _inflightGets[key] = completer;
            options.extra['_dedupe_key'] = key;
            options.extra['_dedupe_completer_owner'] = true;
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          final key = response.requestOptions.extra['_dedupe_key'];
          if (key is String &&
              response.requestOptions.extra['_dedupe_completer_owner'] ==
                  true) {
            final c = _inflightGets.remove(key);
            if (c != null && !c.isCompleted) c.complete(response);
            // Persist to short-TTL cache only on success.
            if (_isCacheable(response.requestOptions.path) &&
                response.statusCode != null &&
                response.statusCode! >= 200 &&
                response.statusCode! < 300) {
              _getCache[key] = _CachedResponse(response, DateTime.now());
              _pruneCache();
            }
          }
          return handler.next(response);
        },
        onError: (error, handler) async {
          // Release the in-flight dedupe slot on error so the next caller
          // can retry with a fresh request.
          final key = error.requestOptions.extra['_dedupe_key'];
          if (key is String &&
              error.requestOptions.extra['_dedupe_completer_owner'] == true) {
            final c = _inflightGets.remove(key);
            if (c != null && !c.isCompleted) c.completeError(error);
          }

          final attemptedFallback =
              error.requestOptions.extra['android_network_fallback'] == true;

          if (!attemptedFallback &&
              !kIsWeb &&
              Platform.isAndroid &&
              (error.type == DioExceptionType.connectionError ||
                  error.type == DioExceptionType.connectionTimeout ||
                  error.type == DioExceptionType.unknown)) {
            final fallbackBaseUrl =
                _resolveAndroidFallbackBaseUrl(error.requestOptions.baseUrl);

            if (fallbackBaseUrl != null &&
                fallbackBaseUrl != error.requestOptions.baseUrl) {
              try {
                final retryOptions = error.requestOptions.copyWith(
                  baseUrl: fallbackBaseUrl,
                  extra: {
                    ...error.requestOptions.extra,
                    'android_network_fallback': true,
                  },
                );

                _dio.options.baseUrl = fallbackBaseUrl;
                await NetworkConfig.setCustomBackendUrl(fallbackBaseUrl);
                ImageUrlHelper.setBaseUrl(fallbackBaseUrl);
                print('🌐 ApiClient fallback baseUrl: $fallbackBaseUrl');

                final response = await _dio.fetch(retryOptions);
                return handler.resolve(response);
              } catch (_) {
                // Keep original error if fallback also fails.
              }
            }
          }

          // Handle 403 - account banned/deactivated → force logout
          if (error.response?.statusCode == 403) {
            final data = error.response?.data;
            final msg = data is Map
                ? (data['error'] is Map
                    ? data['error']['message']?.toString()
                    : data['error']?.toString())
                : null;
            if (msg != null && msg.contains('désactivé')) {
              await clearTokens();
              _sessionExpiredController.add(null);
              print('🔴 Account banned: forcing logout');
            }
          }

          final path = error.requestOptions.path;
          // Ne PAS essayer de refresh pour les endpoints d'auth (login, register, etc.)
          final isAuthEndpoint = path.startsWith('/auth/');
          
          if (error.response?.statusCode == 401 && !isAuthEndpoint) {
            // Try to refresh token
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the request with new token
              final opts = error.requestOptions;
              final token = await getAccessToken();
              opts.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            } else {
              // Refresh failed → session expired, force logout
              await clearTokens();
              _sessionExpiredController.add(null);
              print('🔴 Session expired: token refresh failed, forcing logout');
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  factory ApiClient() {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  /// Builds a stable key for de-duplicating concurrent GET requests.
  /// Includes method, full URL (base + path + query) and the auth bearer
  /// fingerprint so requests for different users are never shared.
  String _dedupeKey(RequestOptions options) {
    final sortedQuery = (options.queryParameters.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)))
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final auth = options.headers[HttpHeaders.authorizationHeader]?.toString();
    // Hash the last 16 chars of the token — enough to separate users
    // without keeping the full secret in a map key.
    final authTail = auth != null && auth.length > 16
        ? auth.substring(auth.length - 16)
        : '';
    return 'GET ${options.baseUrl}${options.path}?$sortedQuery#$authTail';
  }

  /// Keep the short-TTL cache from growing unbounded.
  void _pruneCache() {
    if (_getCache.length < 64) return;
    final now = DateTime.now();
    _getCache.removeWhere(
      (_, v) => now.difference(v.at) > _defaultGetCacheTtl,
    );
  }

  /// Clear the GET cache. Call after mutations (POST/PUT/DELETE) that change
  /// data the user is about to re-read, to avoid serving stale data.
  void invalidateGetCache([String? pathPrefix]) {
    if (pathPrefix == null) {
      _getCache.clear();
      return;
    }
    _getCache.removeWhere((key, _) => key.contains(pathPrefix));
  }

  bool _isAndroidLocalhostUrl(String? url) {
    if (url == null || url.isEmpty || kIsWeb || !Platform.isAndroid) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.host == 'localhost' || uri.host == '127.0.0.1';
  }

  bool _isAndroidEmulatorHostUrl(String? url) {
    if (url == null || url.isEmpty || kIsWeb || !Platform.isAndroid) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.host == '10.0.2.2';
  }

  String _replaceHost(String sourceUrl, String newHost) {
    final source = Uri.parse(sourceUrl);
    return Uri(
      scheme: source.scheme,
      host: newHost,
      port: source.hasPort ? source.port : 9000,
    ).toString();
  }

  String? _resolveAndroidFallbackBaseUrl(String currentBaseUrl) {
    if (kIsWeb || !Platform.isAndroid) return null;

    if (_isAndroidLocalhostUrl(currentBaseUrl)) {
      return _replaceHost(currentBaseUrl, '10.0.2.2');
    }

    if (_isAndroidEmulatorHostUrl(currentBaseUrl)) {
      return NetworkConfig.defaultRealDeviceUrl;
    }

    return null;
  }

  Dio get dio => _dio;
  
  /// Mettre à jour l'URL de base du client API
  Future<void> _updateBaseUrl() async {
    final url = await NetworkConfig.getBackendUrl();
    _dio.options.baseUrl = url;
    print('🌐 ApiClient baseUrl: $url');
    ImageUrlHelper.setBaseUrl(url);
  }
  
  /// Forcer la mise à jour de l'URL (utile après changement de config)
  Future<void> refreshBaseUrl() async {
    await _updateBaseUrl();
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post(
        '/auth/refreshToken',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        await saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Token management
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    if (userId != null) {
      await _storage.write(key: _userIdKey, value: userId);
    }
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
  }

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
