// Package imports:
import 'package:dio/dio.dart';

// Project imports:
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/feed/share_model.dart';

class ShareRepository {
  final ApiClient _apiClient;

  ShareRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Share a post
  Future<ShareModel> sharePost(CreateShareDto dto) async {
    try {
      final payload = <String, dynamic>{
        if (dto.caption != null && dto.caption!.isNotEmpty) 'caption': dto.caption,
        if (dto.privacy != null && dto.privacy!.isNotEmpty) 'privacy': dto.privacy,
      };

      Response<dynamic> response;
      try {
        response = await _apiClient.dio.post(
          '${ApiEndpoints.shareCreate}${dto.postId}/share',
          data: payload,
        );
      } on DioException catch (e) {
        // Some backend versions expect no payload for this endpoint.
        if (e.response?.statusCode == 400 && payload.isNotEmpty) {
          response = await _apiClient.dio.post(
            '${ApiEndpoints.shareCreate}${dto.postId}/share',
          );
        } else {
          rethrow;
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final shareData = data is Map && data.containsKey('data')
            ? data['data']
            : data;

        return ShareModel.fromJson(shareData as Map<String, dynamic>);
      }

      throw Exception(
          response.data['error'] ?? 'Failed to share post');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Unshare a post (not yet implemented in backend)
  Future<void> unsharePost(String postId) async {
    try {
      // Backend doesn't have DELETE /posts/:id/unshare yet
      // This is a placeholder for future implementation
      final response = await _apiClient.dio.delete(
        '${ApiEndpoints.shareDelete}${postId}/unshare',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
            response.data['error'] ?? 'Failed to unshare post');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get all shares for a post
  Future<List<ShareModel>> getPostShares(String postId,
      {int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.sharePost}${postId}/shares',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final sharesData = data is Map && data.containsKey('shares')
            ? data['shares'] as List
            : data is Map && data.containsKey('data')
                ? (data['data'] is Map && data['data'].containsKey('shares')
                    ? data['data']['shares'] as List
                    : data['data'] as List)
                : data is List
                    ? data
                    : [];

        return sharesData
            .map((json) => ShareModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception(
          response.data['error'] ?? 'Failed to get shares');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get user's shared posts
  Future<List<ShareModel>> getUserShares({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.shareUser,
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final sharesData = data is Map && data.containsKey('data')
            ? (data['data'] is List ? data['data'] as List : [])
            : data is List
                ? data
                : [];

        return sharesData
            .map((json) => ShareModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception(
          response.data['error'] ?? 'Failed to get user shares');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Check if user has shared a post (not yet implemented in backend)
  Future<bool> hasUserShared(String postId) async {
    // This endpoint doesn't exist in backend yet
    // TODO: Implement check endpoint in backend or fetch from getUserShares
    return false;
  }

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      final message = data is Map
          ? (data['error'] ?? data['message'] ?? 'Une erreur est survenue')
          : 'Une erreur est survenue';
      return Exception(message);
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Délai de connexion dépassé. Vérifiez votre connexion internet.');
    } else if (e.type == DioExceptionType.connectionError) {
      return Exception(
          'Erreur de connexion. Vérifiez que le backend est démarré.');
    } else {
      return Exception('Erreur réseau: ${e.message}');
    }
  }
}
