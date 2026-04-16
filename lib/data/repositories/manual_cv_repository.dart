import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/profile/manual_cv_model.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';

class ManualCvRepository {
  final ApiClient _apiClient;

  ManualCvRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<ManualCvModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.manualCvCreate,
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return ManualCvModel.fromJson(result);
      }

      throw Exception('Échec de la création du CV');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<ManualCvModel>> getMyCvs() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.manualCvMyCvs,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        if (data is List) {
          return data.map((e) => ManualCvModel.fromJson(e)).toList();
        }
      }

      throw Exception('Échec du chargement des CVs');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ManualCvModel> getById(String cvId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.manualCvGet}$cvId',
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return ManualCvModel.fromJson(data);
      }

      throw Exception('Échec du chargement du CV');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ManualCvModel> update(String cvId, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiEndpoints.manualCvUpdate}$cvId',
        data: data,
      );

      if (response.statusCode == 200) {
        final result = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return ManualCvModel.fromJson(result);
      }

      throw Exception('Échec de la mise à jour du CV');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> delete(String cvId) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiEndpoints.manualCvDelete}$cvId',
      );

      if (response.statusCode != 200) {
        throw Exception('Échec de la suppression du CV');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Uint8List> downloadPdf(String cvId, {String? primaryColor, String? accentColor, String? fontFamily, String? format, String? lang}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (primaryColor != null) queryParams['primaryColor'] = primaryColor;
      if (accentColor != null) queryParams['accentColor'] = accentColor;
      if (fontFamily != null) queryParams['fontFamily'] = fontFamily;
      if (format != null) queryParams['format'] = format;
      if (lang != null) queryParams['lang'] = lang;
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.manualCvDownloadPdf}$cvId',
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

      throw Exception('Échec du téléchargement du PDF');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ManualCvModel> importFromProfile({
    String format = 'standard',
    String language = 'fr',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.manualCvImportProfile,
        data: {'format': format, 'language': language},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return ManualCvModel.fromJson(data);
      }

      throw Exception('Échec de l\'import du profil');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get the CV completeness score from backend.
  /// Returns a Map with: totalScore, maxScore, percentage, label, sections.
  Future<Map<String, dynamic>> getScore(String cvId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.manualCvScore}$cvId',
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return Map<String, dynamic>.from(data as Map);
      }

      throw Exception('Échec du calcul du score');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get the profile CV score aggregated from ALL profile collections.
  /// Does not require a ManualCv — uses real profile data directly.
  /// Returns a Map with: totalScore, maxScore, percentage, label, sections.
  Future<Map<String, dynamic>> getProfileCvScore() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.profileCvScore,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return Map<String, dynamic>.from(data as Map);
      }

      throw Exception('Échec du calcul du score profil');
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
      return Exception('Connexion lente, veuillez réessayer');
    }
    return Exception('Erreur réseau: ${e.message}');
  }
}
