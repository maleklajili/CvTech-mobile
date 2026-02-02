// Dart imports:
// import 'dart:convert'; // Supprimé car non utilisé

// Package imports:
import 'package:dio/dio.dart';

// Project imports:
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/company_model.dart';

class CompanyRepository {
  final ApiClient _apiClient;

  CompanyRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Récupérer toutes les entreprises de l'utilisateur
  Future<List<CompanyModel>> getAll({
    int page = 1,
    int limit = 10,
    String? status,
    bool? verified,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (status != null) queryParams['status'] = status;
      if (verified != null) queryParams['verified'] = verified;

      final response = await _apiClient.dio.get(
        ApiEndpoints.companyGetAll,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        if (data is List) {
          return data.map((e) => CompanyModel.fromJson(e)).toList();
        }
      }

      throw Exception('Échec de la récupération des entreprises');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Récupérer une entreprise par ID
  Future<CompanyModel> getById(String id) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.companyById}$id',
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return CompanyModel.fromJson(data);
      }

      throw Exception('Entreprise non trouvée');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Récupérer les entreprises d'un utilisateur
  Future<List<CompanyModel>> getByUserId(String userId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.companyByUser}$userId',
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        if (data is List) {
          return data.map((e) => CompanyModel.fromJson(e)).toList();
        }
      }

      throw Exception('Échec de la récupération des entreprises');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Créer une nouvelle entreprise
  Future<CompanyModel> create(CompanyModel company) async {
    try {
      final map = company.toJson();
      final formData = FormData.fromMap(map);

      final response = await _apiClient.dio.post(
        ApiEndpoints.companyCreate,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return CompanyModel.fromJson(data);
      }

      throw Exception('Échec de la création de l\'entreprise');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Mettre à jour une entreprise
  Future<CompanyModel> update(String id, CompanyModel company) async {
    try {
      final map = company.toJson();
      final formData = FormData.fromMap(map);

      final response = await _apiClient.dio.put(
        '${ApiEndpoints.companyUpdate}$id',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return CompanyModel.fromJson(data);
      }

      throw Exception('Échec de la mise à jour de l\'entreprise');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Supprimer une entreprise
  Future<void> delete(String id) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiEndpoints.companyDelete}$id',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Échec de la suppression de l\'entreprise');
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
