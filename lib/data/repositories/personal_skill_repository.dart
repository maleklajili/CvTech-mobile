// Dart imports:
// import 'dart:convert'; // Supprimé car non utilisé

// Package imports:
import 'package:dio/dio.dart';

// Project imports:
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/personal_skill_model.dart';

class PersonalSkillRepository {
  final ApiClient _apiClient;

  PersonalSkillRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Récupérer toutes les compétences personnelles de l'utilisateur
  Future<List<PersonalSkillModel>> getAll({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.personalSkillGetAll,
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        if (data is List) {
          return data.map((e) => PersonalSkillModel.fromJson(e)).toList();
        }
      }

      throw Exception('Échec de la récupération des compétences personnelles');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Récupérer une compétence personnelle par ID
  Future<PersonalSkillModel> getById(String id) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.personalSkillById}$id',
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return PersonalSkillModel.fromJson(data);
      }

      throw Exception('Compétence personnelle non trouvée');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Créer une nouvelle compétence personnelle
  Future<PersonalSkillModel> create(PersonalSkillModel skill) async {
    try {
      final map = skill.toJson();

      final response = await _apiClient.dio.post(
        ApiEndpoints.personalSkillCreate,
        data: map,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return PersonalSkillModel.fromJson(data);
      }

      throw Exception('Échec de l\'ajout de la compétence personnelle');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Mettre à jour une compétence personnelle
  Future<PersonalSkillModel> update(String id, PersonalSkillModel skill) async {
    try {
      final map = skill.toJson();

      final response = await _apiClient.dio.put(
        '${ApiEndpoints.personalSkillUpdate}$id',
        data: map,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return PersonalSkillModel.fromJson(data);
      }

      throw Exception('Échec de la mise à jour de la compétence personnelle');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Supprimer une compétence personnelle
  Future<void> delete(String id) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiEndpoints.personalSkillDelete}$id',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Échec de la suppression de la compétence personnelle');
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
