// Dart imports:
import 'dart:io';

// Package imports:
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Project imports:
import 'package:cv_tech/core/config/network_config.dart';
import 'package:cv_tech/core/utils/image_url_helper.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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
          return handler.next(options);
        },
        onError: (error, handler) async {
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

          final path = error.requestOptions.path;
          // Ne PAS essayer de refresh pour les endpoints d'auth (login, register, etc.)
          final isAuthEndpoint = path.startsWith('/auth/');
          
          if (error.response?.statusCode == 401 && !isAuthEndpoint) {
            // Try to refresh token
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the request
              final opts = error.requestOptions;
              final token = await getAccessToken();
              opts.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
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
