// Dart imports:
// import 'dart:convert'; // Supprimé car non utilisé

// Package imports:
import 'package:dio/dio.dart';

// Project imports:
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/language_model.dart';

class LanguageRepository {
  final ApiClient _apiClient;

  LanguageRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Récupérer toutes les langues de l'utilisateur
  Future<List<LanguageModel>> getAll({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.languageGetAll,
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        if (data is List) {
          return data.map((e) => LanguageModel.fromJson(e)).toList();
        }
      }

      throw Exception('Échec de la récupération des langues');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Récupérer une langue par ID
  Future<LanguageModel> getById(String id) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.languageById}$id',
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return LanguageModel.fromJson(data);
      }

      throw Exception('Langue non trouvée');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Créer une nouvelle langue
  Future<LanguageModel> create(LanguageModel language) async {
    try {
      final map = language.toJson();

      final response = await _apiClient.dio.post(
        ApiEndpoints.languageCreate,
        data: map,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return LanguageModel.fromJson(data);
      }

      throw Exception('Échec de l\'ajout de la langue');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Mettre à jour une langue
  Future<LanguageModel> update(String id, LanguageModel language) async {
    try {
      final map = language.toJson();

      final response = await _apiClient.dio.put(
        '${ApiEndpoints.languageUpdate}$id',
        data: map,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return LanguageModel.fromJson(data);
      }

      throw Exception('Échec de la mise à jour de la langue');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Supprimer une langue
  Future<void> delete(String id) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiEndpoints.languageDelete}$id',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Échec de la suppression de la langue');
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
