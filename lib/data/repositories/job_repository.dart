// Dart imports:
// import 'dart:convert'; // Supprimé car non utilisé

// Package imports:
import 'package:dio/dio.dart';

// Project imports:
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/job_model.dart';

class JobRepository {
  final ApiClient _apiClient;

  JobRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Récupérer toutes les offres actives (publiques)
  Future<List<JobModel>> getAll({
    int page = 1,
    int limit = 10,
    String? location,
    String? contractType,
    String? experience,
    List<String>? skills,
    String? companyId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (location != null) queryParams['location'] = location;
      if (contractType != null) queryParams['contractType'] = contractType;
      if (experience != null) queryParams['experience'] = experience;
      if (skills != null && skills.isNotEmpty) queryParams['skills'] = skills.join(',');
      if (companyId != null) queryParams['companyId'] = companyId;

      final response = await _apiClient.dio.get(
        ApiEndpoints.jobGetAll,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        if (data is List) {
          return data.map((e) => JobModel.fromJson(e)).toList();
        }
      }

      throw Exception('Échec de la récupération des offres');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Récupérer mes offres d'emploi
  Future<List<JobModel>> getMyJobs({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.jobMyJobs,
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        if (data is List) {
          return data.map((e) => JobModel.fromJson(e)).toList();
        }
      }

      throw Exception('Échec de la récupération de vos offres');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Récupérer une offre par ID
  Future<JobModel> getById(String id) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.jobById}$id',
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return JobModel.fromJson(data);
      }

      throw Exception('Offre non trouvée');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Récupérer les offres d'une entreprise
  Future<List<JobModel>> getByCompanyId(String companyId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.jobByCompany}$companyId',
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        if (data is List) {
          return data.map((e) => JobModel.fromJson(e)).toList();
        }
      }

      throw Exception('Échec de la récupération des offres');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Créer une nouvelle offre
  Future<JobModel> create(JobModel job) async {
    try {
      final map = job.toJson();

      final response = await _apiClient.dio.post(
        ApiEndpoints.jobCreate,
        data: map,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return JobModel.fromJson(data);
      }

      throw Exception('Échec de la création de l\'offre');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Mettre à jour une offre
  Future<JobModel> update(String id, JobModel job) async {
    try {
      final map = job.toJson();

      final response = await _apiClient.dio.put(
        '${ApiEndpoints.jobUpdate}$id',
        data: map,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return JobModel.fromJson(data);
      }

      throw Exception('Échec de la mise à jour de l\'offre');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Changer le statut d'une offre
  Future<void> toggleStatus(String id, String status) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiEndpoints.jobToggleStatus}$id',
        data: {'status': status},
      );

      if (response.statusCode != 200) {
        throw Exception('Échec du changement de statut');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Toggle featured status
  Future<bool?> toggleFeatured(String id) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiEndpoints.jobFeature}$id',
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          if (data['isFeatured'] is bool) {
            return data['isFeatured'] as bool;
          }
          if (data['data'] is Map<String, dynamic>) {
            final nested = data['data'] as Map<String, dynamic>;
            if (nested['isFeatured'] is bool) {
              return nested['isFeatured'] as bool;
            }
          }
        }
        return null;
      }

      throw Exception('Échec du changement de featured');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Supprimer une offre
  Future<void> delete(String id) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiEndpoints.jobDelete}$id',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Échec de la suppression de l\'offre');
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
