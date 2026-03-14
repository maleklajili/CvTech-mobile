import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/connection/connection_model.dart';

/// Repository pour les opérations de réseau (follow, friends, suggestions, search)
/// Utilise les endpoints existants /user/* du backend
class ConnectionRepository {
  final ApiClient _apiClient;

  ConnectionRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // ==================== FOLLOW / UNFOLLOW ====================

  /// Suivre un utilisateur (POST /user/follow/:userId)
  Future<void> followUser(String userId) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiEndpoints.follow}$userId',
      );
      if (response.statusCode != 200) {
        throw Exception('Erreur lors du follow');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Se désabonner (DELETE /user/unfollow/:userId)
  Future<void> unfollowUser(String userId) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiEndpoints.unfollow}$userId',
      );
      if (response.statusCode != 200) {
        throw Exception('Erreur lors de l\'unfollow');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================== FRIENDS (MUTUAL) ====================

  /// Obtenir mes amis / connexions (GET /user/friends)
  /// Renvoie: { total, friends: [{...user, isFollowing, isFollowedBy, isMutual, mutualFriendsCount}] }
  Future<List<NetworkUser>> getFriends() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.friends);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map) {
          final friends = data['friends'] ?? data['data'] ?? [];
          if (friends is List) {
            return friends
                .whereType<Map<String, dynamic>>()
                .map((f) => NetworkUser.fromJson(f))
                .toList();
          }
        }
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((f) => NetworkUser.fromJson(f))
              .toList();
        }
        return [];
      }
      throw Exception('Erreur lors du chargement des connexions');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================== FOLLOWERS / FOLLOWING ====================

  /// Obtenir mes abonnés (GET /user/followers/:userId)
  /// Le router backend n'accepte pas le param optionnel sans userId,
  /// donc on passe explicitement l'ID de l'utilisateur courant.
  Future<List<NetworkUser>> getFollowers() async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) throw Exception('Utilisateur non connecté');
      final response = await _apiClient.dio.get('${ApiEndpoints.followers}/$userId');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((f) => NetworkUser.fromJson(f))
              .toList();
        }
        if (data is Map) {
          final list = data['data'] ?? data['followers'] ?? [];
          if (list is List) {
            return list
                .whereType<Map<String, dynamic>>()
                .map((f) => NetworkUser.fromJson(f))
                .toList();
          }
        }
        return [];
      }
      throw Exception('Erreur lors du chargement des abonnés');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Obtenir mes abonnements (GET /user/following/:userId)
  /// Le router backend n'accepte pas le param optionnel sans userId,
  /// donc on passe explicitement l'ID de l'utilisateur courant.
  Future<List<NetworkUser>> getFollowing() async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) throw Exception('Utilisateur non connecté');
      final response = await _apiClient.dio.get('${ApiEndpoints.following}/$userId');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((f) => NetworkUser.fromJson(f))
              .toList();
        }
        if (data is Map) {
          final list = data['data'] ?? data['following'] ?? [];
          if (list is List) {
            return list
                .whereType<Map<String, dynamic>>()
                .map((f) => NetworkUser.fromJson(f))
                .toList();
          }
        }
        return [];
      }
      throw Exception('Erreur lors du chargement des abonnements');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================== FOLLOW STATUS ====================

  /// Obtenir le status de follow avec un utilisateur (GET /user/follow-status/:userId)
  /// Renvoie: { isFollowing, followerCount, followingCount }
  Future<FollowStatusInfo> getFollowStatus(String userId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.followStatus}$userId',
      );

      if (response.statusCode == 200) {
        return FollowStatusInfo.fromJson(response.data);
      }
      return const FollowStatusInfo(isFollowing: false);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================== SUGGESTIONS ====================

  /// Obtenir des suggestions d'amis (GET /user/friends/suggestions?page=1&limit=10)
  /// Renvoie: { suggestions: [...], total, currentPage, totalPages }
  Future<List<NetworkUser>> getSuggestions({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.friendsSuggestions,
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map) {
          final suggestions = data['suggestions'] ?? data['data'] ?? [];
          if (suggestions is List) {
            return suggestions
                .whereType<Map<String, dynamic>>()
                .map((s) => NetworkUser.fromJson(s))
                .toList();
          }
        }
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((s) => NetworkUser.fromJson(s))
              .toList();
        }
        return [];
      }
      throw Exception('Erreur lors du chargement des suggestions');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================== SEARCH ====================

  /// Rechercher des utilisateurs (GET /user/friends/search?q=query)
  /// Renvoie: { query, total, results: [{...user, isFollowing, isFollowedBy, isMutual, mutualFriendsCount}] }
  Future<List<NetworkUser>> searchUsers(String query) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.friendsSearch,
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map) {
          final results = data['results'] ?? data['data'] ?? [];
          if (results is List) {
            return results
                .whereType<Map<String, dynamic>>()
                .map((r) => NetworkUser.fromJson(r))
                .toList();
          }
        }
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((r) => NetworkUser.fromJson(r))
              .toList();
        }
        return [];
      }
      throw Exception('Erreur lors de la recherche');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================== MUTUAL FRIENDS ====================

  /// Obtenir les amis en commun avec un utilisateur (GET /user/mutual-friends/:userId)
  Future<List<NetworkUser>> getMutualFriends(String userId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.mutualFriends}$userId',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((f) => NetworkUser.fromJson(f))
              .toList();
        }
        if (data is Map) {
          final list = data['data'] ?? [];
          if (list is List) {
            return list
                .whereType<Map<String, dynamic>>()
                .map((f) => NetworkUser.fromJson(f))
                .toList();
          }
        }
        return [];
      }
      throw Exception('Erreur lors du chargement des amis en commun');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================== ERROR HANDLING ====================

  Exception _handleDioError(DioException e) {
    if (kDebugMode) print('❌ [ConnectionRepo] DioError: ${e.message}');
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data['error'] != null) {
        final error = data['error'];
        if (error is Map && error['message'] != null) {
          return Exception(error['message']);
        }
        return Exception(error.toString());
      }
      return Exception('Erreur ${e.response!.statusCode}');
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Timeout de connexion');
    }
    return Exception('Erreur réseau');
  }
}
