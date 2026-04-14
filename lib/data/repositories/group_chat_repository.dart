import 'package:dio/dio.dart';
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/models/group_chat_model.dart';

class GroupChatRepository {
  final ApiClient _apiClient;

  GroupChatRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Get chat messages for a group
  Future<List<GroupChatMessage>> getGroupMessages(
    String groupId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/messages/groups/$groupId',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      final data = _extractData(response.data);
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .map(GroupChatMessage.fromJson)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Send a message to a group chat
  Future<GroupChatMessage> sendMessage(
    String groupId,
    String content,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/messages/groups/$groupId',
        data: {'text': content},
      );

      final data = _extractData(response.data);
      return GroupChatMessage.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Send a media/file message to a group chat
  Future<GroupChatMessage> sendFileMessage({
    required String groupId,
    required String filePath,
    String? fileName,
    String type = 'document',
    String? content,
  }) async {
    try {
      final formData = FormData.fromMap({
        'type': type,
        if (content != null && content.trim().isNotEmpty) 'content': content.trim(),
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      Response<dynamic> response;
      try {
        response = await _apiClient.dio.post(
          '/messages/groups/$groupId/media',
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        );
      } on DioException catch (e) {
        final status = e.response?.statusCode ?? 0;
        if (status == 404 || status == 405) {
          response = await _apiClient.dio.post(
            '/messages/groups/$groupId',
            data: formData,
            options: Options(contentType: 'multipart/form-data'),
          );
        } else {
          rethrow;
        }
      }

      final data = _extractData(response.data);
      return GroupChatMessage.fromJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Mark messages as seen
  Future<void> markMessagesAsSeen(String groupId, List<String> messageIds) async {
    try {
      await _apiClient.dio.patch(
        '/messages/read',
        data: {'groupId': groupId, 'messageIds': messageIds},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String groupId, String messageId) async {
    try {
      await _apiClient.dio.delete(
        '/messages/groups/$groupId/self',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ── Helper methods ──

  dynamic _extractData(dynamic response) {
    if (response is Map) {
      if (response.containsKey('data')) return response['data'];
      return response;
    }
    return response;
  }

  String _handleDioError(DioException error) {
    if (error.response?.data is Map) {
      final errorMap = error.response?.data as Map;
      if (errorMap.containsKey('error')) {
        final errorObj = errorMap['error'];
        if (errorObj is Map && errorObj.containsKey('message')) {
          return errorObj['message'].toString();
        }
      }
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout => 'Connexion en attente',
      DioExceptionType.receiveTimeout => 'Réception en attente',
      DioExceptionType.sendTimeout => 'Envoi en attente',
      DioExceptionType.connectionError => 'Erreur de connexion',
      DioExceptionType.unknown => 'Erreur inconnue: ${error.message}',
      _ => 'Une erreur est survenue',
    };
  }
}
