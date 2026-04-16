// Package imports:
import 'package:dio/dio.dart';

// Project imports:
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';

class ChatbotRepository {
  final ApiClient _apiClient;

  ChatbotRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Send a message to the AI chatbot.
  /// [message] - the user's message
  /// [history] - previous conversation messages for context
  /// [context] - optional context (e.g. CV data)
  /// Returns { 'reply': String, 'model': String }
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    List<Map<String, dynamic>> history = const [],
    String context = '',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.chatbotMessage,
        data: {
          'message': message,
          'history': history,
          'context': context,
        },
      );

      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        return {
          'reply': data['data']['reply'] ?? '',
          'model': data['data']['model'] ?? 'unknown',
        };
      }

      throw Exception(data['message'] ?? 'Erreur inconnue');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Check if the chatbot service is available.
  Future<bool> checkStatus() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.chatbotStatus,
      );

      final data = response.data;
      return data['data']?['available'] == true;
    } catch (_) {
      return false;
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final body = e.response?.data;
      final message = (body is Map ? body['message'] : null)?.toString() ??
          'Erreur serveur (${e.response?.statusCode})';
      // If Ollama is not running, give a friendlier message
      if (e.response?.statusCode == 500) {
        return Exception('Le serveur Ollama n\'est pas démarré. Lancez "ollama serve" puis réessayez.');
      }
      return Exception(message);
    }
    if (e.type == DioExceptionType.connectionTimeout) {
      return Exception('Connexion au serveur expirée');
    }
    return Exception('Erreur réseau: ${e.message}');
  }
}
