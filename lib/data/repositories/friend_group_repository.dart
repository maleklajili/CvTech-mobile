import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/friend_group_model.dart';

class FriendGroupRepository {
  final ApiClient _apiClient;

  FriendGroupRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Get all friend groups for the current user
  Future<List<FriendGroup>> getAll() async {
    try {
      final response = await _getWithFallback(ApiEndpoints.friendGroupGetAll);
      return _extractGroups(_normalizeResponseData(response.data));
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw 'Erreur lors du chargement des groupes: ${e.toString()}';
    }
  }

  /// Get a friend group by ID
  Future<FriendGroup> getById(String groupId) async {
    try {
      final response = await _getWithFallback(
        '${ApiEndpoints.friendGroupById}$groupId',
      );
      final data = _extractData(_normalizeResponseData(response.data));
      return FriendGroup.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Create a new friend group
  Future<FriendGroup> create({
    required String name,
    required String description,
    String? icon,
    String? color,
  }) async {
    try {
      final payload = {
        'name': name,
        'description': description,
        if (icon != null) 'icon': icon,
        if (color != null) 'color': color,
      };

      final response = await _postWithFallback(
        ApiEndpoints.friendGroupCreate,
        data: payload,
      );

      final data = _extractData(_normalizeResponseData(response.data));
      return FriendGroup.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update a friend group
  Future<FriendGroup> update(
    String groupId, {
    required String name,
    required String description,
    String? icon,
    String? color,
  }) async {
    try {
      final payload = {
        'name': name,
        'description': description,
        if (icon != null) 'icon': icon,
        if (color != null) 'color': color,
      };

      final response = await _putWithFallback(
        '${ApiEndpoints.friendGroupById}$groupId',
        data: payload,
      );

      final data = _extractData(_normalizeResponseData(response.data));
      return FriendGroup.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Delete a friend group
  Future<void> delete(String groupId) async {
    try {
      await _deleteWithFallback('${ApiEndpoints.friendGroupById}$groupId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Add members to a friend group
  Future<FriendGroup> addMembers(String groupId, List<String> memberIds) async {
    try {
      if (memberIds.isEmpty) {
        throw Exception('At least one member must be added');
      }

      final payload = {'memberIds': memberIds};

      final response = await _postWithFallback(
        '${ApiEndpoints.friendGroupAddMembers}$groupId/add-members',
        data: payload,
      );

      final data = _extractData(_normalizeResponseData(response.data));
      return FriendGroup.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Remove members from a friend group
  Future<FriendGroup> removeMembers(String groupId, List<String> memberIds) async {
    try {
      if (memberIds.isEmpty) {
        throw Exception('At least one member must be removed');
      }

      final payload = {'memberIds': memberIds};

      final response = await _deleteWithFallback(
        '${ApiEndpoints.friendGroupRemoveMembers}$groupId/remove-members',
        data: payload,
      );

      final data = _extractData(_normalizeResponseData(response.data));
      return FriendGroup.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Search friend groups
  Future<List<FriendGroup>> search(String query) async {
    try {
      if (query.trim().isEmpty) {
        return getAll();
      }

      final response = await _getWithFallback(
        '${ApiEndpoints.friendGroupSearch}${query.trim()}',
      );
      return _extractGroups(_normalizeResponseData(response.data));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<dynamic>> _getWithFallback(String path) async {
    DioException? lastNotFound;
    DioException? lastError;
    
    for (final candidate in _pathCandidates(path)) {
      try {
        return await _apiClient.dio.get(
          candidate,
          options: Options(responseType: ResponseType.plain),
        );
      } on DioException catch (e) {
        lastError = e;
        // Only continue trying if it's specifically a 404 (route not found)
        if (e.response?.statusCode == 404) {
          lastNotFound = e;
          continue;
        }
        // For any other error (401, 500, etc), throw immediately - don't keep trying
        rethrow;
      }
    }

    if (lastNotFound != null) {
      throw lastNotFound;
    }
    if (lastError != null) {
      throw lastError;
    }

    final request = RequestOptions(path: path);
    throw DioException(
      requestOptions: request,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: request,
        statusCode: 404,
        statusMessage: 'No endpoint candidate matched',
      ),
      error: 'Aucun endpoint valide trouve pour $path',
    );
  }

  Future<Response<dynamic>> _postWithFallback(
    String path, {
    Object? data,
  }) async {
    DioException? lastNotFound;
    DioException? lastError;
    
    for (final candidate in _pathCandidates(path)) {
      try {
        return await _apiClient.dio.post(
          candidate,
          data: data,
          options: Options(responseType: ResponseType.plain),
        );
      } on DioException catch (e) {
        lastError = e;
        if (e.response?.statusCode == 404) {
          lastNotFound = e;
          continue;
        }
        rethrow;
      }
    }
    if (lastNotFound != null) {
      throw lastNotFound;
    }
    if (lastError != null) {
      throw lastError;
    }

    final request = RequestOptions(path: path);
    throw DioException(
      requestOptions: request,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: request,
        statusCode: 404,
        statusMessage: 'No endpoint candidate matched',
      ),
      error: 'Aucun endpoint valide trouve pour $path',
    );
  }

  Future<Response<dynamic>> _putWithFallback(
    String path, {
    Object? data,
  }) async {
    DioException? lastNotFound;
    DioException? lastError;
    
    for (final candidate in _pathCandidates(path)) {
      try {
        return await _apiClient.dio.put(
          candidate,
          data: data,
          options: Options(responseType: ResponseType.plain),
        );
      } on DioException catch (e) {
        lastError = e;
        if (e.response?.statusCode == 404) {
          lastNotFound = e;
          continue;
        }
        rethrow;
      }
    }
    if (lastNotFound != null) {
      throw lastNotFound;
    }
    if (lastError != null) {
      throw lastError;
    }

    final request = RequestOptions(path: path);
    throw DioException(
      requestOptions: request,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: request,
        statusCode: 404,
        statusMessage: 'No endpoint candidate matched',
      ),
      error: 'Aucun endpoint valide trouve pour $path',
    );
  }

  Future<Response<dynamic>> _deleteWithFallback(
    String path, {
    Object? data,
  }) async {
    DioException? lastNotFound;
    DioException? lastError;
    
    for (final candidate in _pathCandidates(path)) {
      try {
        return await _apiClient.dio.delete(
          candidate,
          data: data,
          options: Options(responseType: ResponseType.plain),
        );
      } on DioException catch (e) {
        lastError = e;
        if (e.response?.statusCode == 404) {
          lastNotFound = e;
          continue;
        }
        rethrow;
      }
    }
    if (lastNotFound != null) {
      throw lastNotFound;
    }
    if (lastError != null) {
      throw lastError;
    }

    final request = RequestOptions(path: path);
    throw DioException(
      requestOptions: request,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: request,
        statusCode: 404,
        statusMessage: 'No endpoint candidate matched',
      ),
      error: 'Aucun endpoint valide trouve pour $path',
    );
  }

  List<String> _pathCandidates(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    final withSlash = normalized.endsWith('/') ? normalized : '$normalized/';

    final candidates = <String>[
      normalized,
      withSlash,
    ];

    if (!normalized.startsWith('/api/')) {
      candidates.add('/api$normalized');
      candidates.add('/api$withSlash');
    }

    return candidates.toSet().toList();
  }

  // ── Helper methods ──

  dynamic _normalizeResponseData(dynamic data) {
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) {
        return <String, dynamic>{};
      }

      try {
        return jsonDecode(trimmed);
      } catch (_) {
        return {
          'message': trimmed,
          'raw': trimmed,
        };
      }
    }

    return data;
  }

  List<FriendGroup> _extractGroups(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(FriendGroup.fromJson)
          .toList();
    } else if (data is Map) {
      final dynamic rawData = data['data'];
      final list = rawData is List
          ? rawData
          : (rawData is Map
              ? (rawData['groups'] ?? rawData['friendGroups'] ?? [])
              : (data['groups'] ?? data['friendGroups'] ?? []));
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .map(FriendGroup.fromJson)
            .toList();
      }
    }
    return [];
  }

  Map<String, dynamic> _extractData(dynamic data) {
    if (data is Map) {
      final result = Map<String, dynamic>.from(data);
      // Unwrap if response is nested
      if (result.containsKey('data') && result['data'] is Map) {
        return Map<String, dynamic>.from(result['data']);
      }
      return result;
    }
    return {};
  }

  String _handleDioError(DioException e) {
    // Log the full error for debugging
    print('🔴 DioException: ${e.type} - ${e.message}');
    if (e.response != null) {
      print('   Status: ${e.response!.statusCode}');
      print('   Data: ${e.response!.data}');
    }

    if (e.response?.data is String && (e.response!.data as String).isNotEmpty) {
      final payload = (e.response!.data as String).trim();
      try {
        final parsed = jsonDecode(payload);
        if (parsed is Map) {
          final nested = parsed['error'];
          if (nested is Map && nested['message'] != null) {
            return nested['message'].toString();
          }
          if (parsed['message'] != null) {
            return parsed['message'].toString();
          }
        }
      } catch (_) {
        return payload;
      }

      return payload;
    }

    if (e.response?.data is Map) {
      final data = Map<String, dynamic>.from(e.response!.data as Map);
      final nestedError = data['error'];
      if (nestedError is Map && nestedError['message'] != null) {
        return nestedError['message'].toString();
      }
      if (data['message'] != null) {
        return data['message'].toString();
      }
      if (data['error'] is String) {
        return data['error'].toString();
      }
    }

    if (e.error != null) {
      final nested = e.error.toString().trim();
      if (nested.isNotEmpty && nested.toLowerCase() != 'null') {
        return nested;
      }
    }

    final msg = e.message?.trim();

    return switch (e.type) {
      DioExceptionType.connectionTimeout => 'Timeout de connexion',
      DioExceptionType.receiveTimeout => 'Timeout de réception',
      DioExceptionType.sendTimeout => 'Timeout d\'envoi',
      DioExceptionType.badResponse => 'Erreur serveur: ${e.response?.statusCode}',
      DioExceptionType.badCertificate => 'Erreur de certificat SSL',
      DioExceptionType.connectionError => 'Impossible de se connecter au serveur',
      DioExceptionType.unknown =>
        (msg != null && msg.isNotEmpty && msg.toLowerCase() != 'null')
            ? 'Erreur: $msg'
            : 'Erreur reseau inconnue. Verifiez la connexion et l\'URL backend.',
      _ => (msg != null && msg.isNotEmpty && msg.toLowerCase() != 'null')
          ? msg
          : 'Une erreur est survenue',
    };
  }
}
