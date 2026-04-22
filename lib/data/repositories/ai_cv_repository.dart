import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/profile/ai_cv_model.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';

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
        options: Options(
          // LLM (llama3.2 on CPU) can take 300-600s — must exceed backend timeout
          receiveTimeout: const Duration(seconds: 600),
          sendTimeout: const Duration(seconds: 30),
        ),
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
        options: Options(
          receiveTimeout: const Duration(seconds: 600),
          sendTimeout: const Duration(seconds: 30),
        ),
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

  /// Download CV as PDF from backend
  Future<Uint8List> downloadPdf(String cvId, {String? primaryColor, String? accentColor, String? fontFamily, String? format, String? lang}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (primaryColor != null) queryParams['primaryColor'] = primaryColor;
      if (accentColor != null) queryParams['accentColor'] = accentColor;
      if (fontFamily != null) queryParams['fontFamily'] = fontFamily;
      if (format != null) queryParams['format'] = format;
      if (lang != null) queryParams['lang'] = lang;
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.aiCvDownloadPdf}$cvId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final bytes = Uint8List.fromList(response.data as List<int>);
        if (bytes.isEmpty) {
          throw Exception('Le PDF généré est vide');
        }
        return bytes;
      }

      throw Exception('Échec du téléchargement du PDF (status: ${response.statusCode})');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get CV generation info (plan, coins, template tiers, costs)
  Future<Map<String, dynamic>> getCvInfo() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.aiCvInfo);
      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return Map<String, dynamic>.from(data as Map);
      }
      throw Exception('Échec du chargement des infos CV');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Improve bio and classify skills using AI
  Future<Map<String, dynamic>> improveBio() async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.aiCvImproveBio,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return Map<String, dynamic>.from(data as Map);
      }

      throw Exception('Échec de l\'amélioration du profil');
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
