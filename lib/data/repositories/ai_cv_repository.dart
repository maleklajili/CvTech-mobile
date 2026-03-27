import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/profile/ai_cv_model.dart';
import 'package:dio/dio.dart';

class AiCvRepository {
  final ApiClient _apiClient;

  AiCvRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Generate a new AI CV based on user profile
  Future<AiCvModel> generate({
    String language = 'fr',
    String section = 'full',
    String format = 'standard',
    String? customPrompt,
  }) async {
    try {
      final body = <String, dynamic>{
        'language': language,
        'section': section,
        'format': format,
      };
      if (customPrompt != null && customPrompt.isNotEmpty) {
        body['customPrompt'] = customPrompt;
      }

      final response = await _apiClient.dio.post(
        ApiEndpoints.aiCvGenerate,
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return AiCvModel.fromJson(data);
      }

      throw Exception('Échec de la génération du CV');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Reformulate an existing AI CV
  Future<AiCvModel> reformulate({
    required String cvId,
    String? instructions,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (instructions != null && instructions.isNotEmpty) {
        body['instructions'] = instructions;
      }

      final response = await _apiClient.dio.post(
        '${ApiEndpoints.aiCvReformulate}$cvId',
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return AiCvModel.fromJson(data);
      }

      throw Exception('Échec de la reformulation du CV');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get all user's AI-generated CVs
  Future<List<AiCvModel>> getMyCvs() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.aiCvMyCvs,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        if (data is List) {
          return data.map((e) => AiCvModel.fromJson(e)).toList();
        }
      }

      throw Exception('Échec du chargement des CVs');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Delete a generated CV
  Future<void> delete(String cvId) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiEndpoints.aiCvDelete}$cvId',
      );

      if (response.statusCode != 200) {
        throw Exception('Échec de la suppression du CV');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.response?.data is Map) {
      final error = e.response!.data['error'];
      if (error is Map && error['message'] != null) {
        return Exception(error['message']);
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('La génération prend du temps, veuillez réessayer');
    }
    return Exception('Erreur réseau: ${e.message}');
  }
}
