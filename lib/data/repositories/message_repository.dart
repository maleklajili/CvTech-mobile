import 'package:dio/dio.dart';
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/message/message_model.dart';

class MessageRepository {
  final ApiClient _apiClient;

  MessageRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // ==================== CHATS LIST ====================

  /// Get recent chat previews (sorted by latest message)
  Future<List<ChatPreview>> getRecentChats() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.messageChats);

      if (response.statusCode == 200) {
        final data = response.data;
        final chatsData = data is Map ? (data['data'] ?? data['chats'] ?? data) : data;

        if (chatsData is List) {
          return chatsData
              .whereType<Map<String, dynamic>>()
              .map((c) => ChatPreview.fromJson(c))
              .toList();
        }
        return [];
      }
      throw Exception('Erreur lors du chargement des chats');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================== CONVERSATION ====================

  /// Get messages for a conversation with a specific user
  Future<List<MessageModel>> getConversation(String userId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.messageConversation}$userId',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final msgs = data is Map ? (data['data'] ?? data['messages'] ?? data) : data;

        if (msgs is List) {
          return msgs
              .whereType<Map<String, dynamic>>()
              .map((m) => MessageModel.fromJson(m))
              .toList();
        }
        return [];
      }
      throw Exception('Erreur lors du chargement de la conversation');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================== SEND ====================

  /// Send a text message
  Future<MessageModel> sendMessage({
    required String receiverId,
    required String text,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.messageSend,
        data: {
          'receiverId': receiverId,
          'type': 'text',
          'payload': {'text': text},
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final msgData = data is Map ? (data['data'] ?? data) : data;
        return MessageModel.fromJson(msgData);
      }
      throw Exception('Erreur lors de l\'envoi du message');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Send a media message (image, video, document)
  Future<MessageModel> sendMediaMessage({
    required String receiverId,
    required String filePath,
    required String type,
    String? fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'type': type,
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      final response = await _apiClient.dio.post(
        '${ApiEndpoints.messageMedia}$receiverId',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final msgData = data is Map ? (data['data'] ?? data) : data;
        return MessageModel.fromJson(msgData);
      }
      throw Exception('Erreur lors de l\'envoi du fichier');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================== READ / DELETE ====================

  /// Mark messages as read
  Future<void> markAsRead(List<String> messageIds) async {
    try {
      await _apiClient.dio.patch(
        '${ApiEndpoints.message}/read',
        data: {'messageIds': messageIds},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _apiClient.dio.delete(
        '${ApiEndpoints.messageDelete}$messageId',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Soft-delete a message for current user only
  Future<void> softDeleteMessage(String messageId) async {
    try {
      await _apiClient.dio.delete(
        '${ApiEndpoints.message}/$messageId/self',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Search messages
  Future<List<Map<String, dynamic>>> searchMessages(String query) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.messageSearch,
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final results = data is Map ? (data['data'] ?? data['results'] ?? data) : data;
        if (results is List) {
          return results.whereType<Map<String, dynamic>>().toList();
        }
        return [];
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================== CONVERSATION MANAGEMENT ====================

  /// Supprimer une conversation pour les deux utilisateurs (DELETE /messages/conversation/:otherUserId)
  Future<void> deleteConversation(String otherUserId) async {
    try {
      await _apiClient.dio.delete(
        '${ApiEndpoints.messageConversation}$otherUserId',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Masquer une conversation pour l'utilisateur courant (DELETE /messages/conversation/:otherUserId/self)
  Future<void> softDeleteConversation(String otherUserId) async {
    try {
      await _apiClient.dio.delete(
        '${ApiEndpoints.messageConversation}$otherUserId/self',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================== MESSAGE EDIT ====================

  /// Modifier un message (PATCH /messages/:messageId)
  Future<MessageModel> updateMessage({
    required String messageId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '${ApiEndpoints.message}/$messageId',
        data: {'payload': payload},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final msgData = data is Map ? (data['data'] ?? data) : data;
        return MessageModel.fromJson(msgData);
      }
      throw Exception('Erreur lors de la modification du message');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================== ERROR HANDLING ====================

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      final message = data is Map ? (data['message'] ?? data['error'] ?? 'Erreur serveur') : 'Erreur serveur';
      return Exception('$message (${e.response?.statusCode})');
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Connexion au serveur expirée');
    }
    if (e.type == DioExceptionType.connectionError) {
      return Exception('Impossible de se connecter au serveur');
    }
    return Exception('Erreur réseau: ${e.message}');
  }
}
