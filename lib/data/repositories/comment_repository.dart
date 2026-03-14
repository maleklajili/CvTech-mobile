// Package imports:
import 'package:dio/dio.dart';

// Project imports:
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/feed/comment_model.dart';

class CommentRepository {
  final ApiClient _apiClient;

  CommentRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Create a new comment or reply
  Future<CommentModel> createComment(CreateCommentDto dto) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.commentCreate,
        data: dto.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final commentData = data is Map && data.containsKey('data')
            ? data['data']
            : data;

        return CommentModel.fromJson(commentData as Map<String, dynamic>);
      }

      throw Exception(
          response.data['error'] ?? 'Failed to create comment');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get all comments for a post
  Future<List<CommentModel>> getPostComments(String postId,
      {int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.commentPost}$postId',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final commentsData = data is Map && data.containsKey('comments')
            ? data['comments'] as List
            : data is Map && data.containsKey('data')
                ? (data['data'] is Map && data['data'].containsKey('comments')
                    ? data['data']['comments'] as List
                    : data['data'] as List)
                : data is List
                    ? data
                    : [];

        return commentsData
            .map((json) => CommentModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception(
          response.data['error'] ?? 'Failed to get comments');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get replies for a comment
  Future<List<CommentModel>> getCommentReplies(String commentId,
      {int limit = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.commentReplies}$commentId/replies',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final repliesData = data is Map && data.containsKey('data')
            ? (data['data'] is List ? data['data'] as List : [])
            : data is List
                ? data
                : [];

        return repliesData
            .map((json) => CommentModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception(
          response.data['error'] ?? 'Failed to get replies');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update a comment
  Future<void> updateComment(String commentId, UpdateCommentDto dto) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiEndpoints.commentUpdate}$commentId',
        data: dto.toJson(),
      );

      if (response.statusCode != 200) {
        throw Exception(
            response.data['error'] ?? 'Failed to update comment');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiEndpoints.commentDelete}$commentId',
      );

      if (response.statusCode != 200) {
        throw Exception(
            response.data['error'] ?? 'Failed to delete comment');
      }
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
