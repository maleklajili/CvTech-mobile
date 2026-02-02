// Dart imports:
// import 'dart:convert'; // Supprimé car non utilisé

// Package imports:
import 'package:dio/dio.dart';

// Project imports:
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/technical_skill_model.dart';

class TechnicalSkillRepository {
  final ApiClient _apiClient;

  TechnicalSkillRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Récupérer toutes les compétences techniques de l'utilisateur
  Future<List<TechnicalSkillModel>> getAll({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.technicalSkillGetAll,
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        if (data is List) {
          return data.map((e) => TechnicalSkillModel.fromJson(e)).toList();
        }
      }

      throw Exception('Échec de la récupération des compétences techniques');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Récupérer les compétences techniques groupées par catégorie
  Future<Map<String, List<TechnicalSkillModel>>> getGroupedByCategory() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.technicalSkillGrouped,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        final Map<String, List<TechnicalSkillModel>> grouped = {};
        
        if (data is Map) {
          data.forEach((key, value) {
            if (value is List) {
              grouped[key] = value.map((e) => TechnicalSkillModel.fromJson(e)).toList();
            }
          });
        }

        return grouped;
      }

      throw Exception('Échec de la récupération des compétences techniques');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Récupérer une compétence technique par ID
  Future<TechnicalSkillModel> getById(String id) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.technicalSkillById}$id',
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return TechnicalSkillModel.fromJson(data);
      }

      throw Exception('Compétence technique non trouvée');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Créer une nouvelle compétence technique
  Future<TechnicalSkillModel> create(TechnicalSkillModel skill) async {
    try {
      final map = skill.toJson();

      final response = await _apiClient.dio.post(
        ApiEndpoints.technicalSkillCreate,
        data: map,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return TechnicalSkillModel.fromJson(data);
      }

      throw Exception('Échec de l\'ajout de la compétence technique');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Mettre à jour une compétence technique
  Future<TechnicalSkillModel> update(String id, TechnicalSkillModel skill) async {
    try {
      final map = skill.toJson();

      final response = await _apiClient.dio.put(
        '${ApiEndpoints.technicalSkillUpdate}$id',
        data: map,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return TechnicalSkillModel.fromJson(data);
      }

      throw Exception('Échec de la mise à jour de la compétence technique');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Supprimer une compétence technique
  Future<void> delete(String id) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiEndpoints.technicalSkillDelete}$id',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Échec de la suppression de la compétence technique');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    if (error.response?.data != null) {
      final message = error.response!.data['message'] ?? 
                     error.response!.data['error'] ?? 
                     'Une erreur est survenue';
      return Exception(message);
    }
    return Exception(error.message ?? 'Erreur de connexion');
  }
}
