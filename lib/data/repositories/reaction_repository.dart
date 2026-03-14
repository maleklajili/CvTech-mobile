// Package imports:
import 'package:dio/dio.dart';

// Project imports:
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/feed/reaction_model.dart';

class ReactionRepository {
  final ApiClient _apiClient;

  ReactionRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // ============ POST REACTIONS ============

  /// Toggle reaction on a post (add, update, or remove)
  Future<Map<String, dynamic>> togglePostReaction(
      String postId, ReactionType type) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiEndpoints.reactionToggle}$postId/toggle',
        data: {'type': type.value},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final resultData = data is Map && data.containsKey('data')
            ? data['data']
            : data;

        return {
          'userReaction': resultData['userReaction'],
          'reactionCounts':
              ReactionCounts.fromJson(resultData['reactionCounts']),
          'wasAdded': resultData['wasAdded'] ?? false,
        };
      }

      throw Exception(
          response.data['error'] ?? 'Failed to toggle reaction');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Remove reaction from a post
  Future<void> removePostReaction(String postId) async {
    try {
      await _apiClient.dio.delete(
        '${ApiEndpoints.reactionDelete}$postId',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get reaction counts for a post
  Future<ReactionCounts> getPostReactionCounts(String postId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.reactionCounts}$postId/counts',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final reactionData = data is Map && data.containsKey('data')
            ? data['data']['reactionCounts']
            : data['reactionCounts'];

        return ReactionCounts.fromJson(reactionData);
      }

      throw Exception(
          response.data['error'] ?? 'Failed to get reaction counts');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get reaction data for a post (counts + user reaction)
  Future<Map<String, dynamic>> getPostReactionData(String postId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.reactionData}$postId/data',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final resultData = data is Map && data.containsKey('data')
            ? data['data']
            : data;

        return {
          'reactionCounts':
              ReactionCounts.fromJson(resultData['reactionCounts']),
          'userReaction': resultData['userReaction'] != null
              ? ReactionType.fromString(resultData['userReaction'])
              : null,
        };
      }

      throw Exception(
          response.data['error'] ?? 'Failed to get reaction data');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ============ COMMENT REACTIONS ============

  /// Toggle reaction on a comment (add, update, or remove)
  Future<Map<String, dynamic>> toggleCommentReaction(
      String commentId, ReactionType type) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiEndpoints.reactionCommentToggle}$commentId/toggle',
        data: {'type': type.value},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final resultData = data is Map && data.containsKey('data')
            ? data['data']
            : data;

        return {
          'userReaction': resultData['userReaction'],
          'reactionCounts':
              ReactionCounts.fromJson(resultData['reactionCounts']),
          'wasAdded': resultData['wasAdded'] ?? false,
        };
      }

      throw Exception(
          response.data['error'] ?? 'Failed to toggle comment reaction');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Remove reaction from a comment
  Future<void> removeCommentReaction(String commentId) async {
    try {
      await _apiClient.dio.delete(
        '${ApiEndpoints.reactionCommentDelete}$commentId',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get reaction data for a comment (counts + user reaction)
  Future<Map<String, dynamic>> getCommentReactionData(String commentId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.reactionCommentData}$commentId/data',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final resultData = data is Map && data.containsKey('data')
            ? data['data']
            : data;

        return {
          'reactionCounts':
              ReactionCounts.fromJson(resultData['reactionCounts']),
          'userReaction': resultData['userReaction'] != null
              ? ReactionType.fromString(resultData['userReaction'])
              : null,
        };
      }

      throw Exception(
          response.data['error'] ?? 'Failed to get comment reaction data');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
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
