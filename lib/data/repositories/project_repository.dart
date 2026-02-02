// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:dio/dio.dart';

// Project imports:
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/profile/project_model.dart';

class ProjectRepository {
  final ApiClient _apiClient;

  ProjectRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Récupérer tous les projets de l'utilisateur
  Future<List<ProjectModel>> getAll({bool? featured}) async {
    try {
      final queryParams = featured != null ? {'featured': featured} : null;
      final response = await _apiClient.dio.get(
        ApiEndpoints.projectGetAll,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        if (data is List) {
          return data.map((e) => ProjectModel.fromJson(e)).toList();
        }
      }

      throw Exception('Échec de la récupération des projets');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Récupérer un projet par ID
  Future<ProjectModel> getById(String id) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.projectById}$id',
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return ProjectModel.fromJson(data);
      }

      throw Exception('Projet non trouvé');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Créer un nouveau projet
  Future<ProjectModel> create(ProjectModel project) async {
    try {
      final map = <String, dynamic>{};

      // Champs de base - exactement comme le frontend
      map['title'] = project.title;
      map['description'] = project.description;
      map['category'] = project.category;
      map['projectType'] = project.projectType;

      // Dates - format ISO comme le frontend (toISO)
      map['startDate'] = project.startDate.toIso8601String();
      // endDate vide si current est true, comme le frontend
      map['endDate'] =
          project.current ? '' : (project.endDate?.toIso8601String() ?? '');

      // Boolean comme JSON string
      map['current'] = project.current.toString();

      // Champs optionnels
      if (project.color != null) {
        map['color'] = project.color;
      }
      if (project.liveUrl != null && project.liveUrl!.isNotEmpty) {
        map['liveUrl'] = project.liveUrl;
      }
      if (project.githubUrl != null && project.githubUrl!.isNotEmpty) {
        map['githubUrl'] = project.githubUrl;
      }

      // Technologies en JSON string
      map['technologies'] = jsonEncode(project.technologies);

      final formData = FormData.fromMap(map);

      final response = await _apiClient.dio.post(
        ApiEndpoints.projectCreate,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return ProjectModel.fromJson(data);
      }

      throw Exception('Échec de la création du projet');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Mettre à jour un projet
  Future<ProjectModel> update(String id, ProjectModel project) async {
    try {
      final map = <String, dynamic>{};

      // Champs de base - exactement comme le frontend
      map['title'] = project.title;
      map['description'] = project.description;
      map['category'] = project.category;
      map['projectType'] = project.projectType;

      // Dates - format ISO comme le frontend (toISO)
      map['startDate'] = project.startDate.toIso8601String();
      // endDate vide si current est true, comme le frontend
      map['endDate'] =
          project.current ? '' : (project.endDate?.toIso8601String() ?? '');

      // Boolean comme JSON string
      map['current'] = project.current.toString();

      // Champs optionnels
      if (project.color != null) {
        map['color'] = project.color;
      }
      if (project.liveUrl != null && project.liveUrl!.isNotEmpty) {
        map['liveUrl'] = project.liveUrl;
      }
      if (project.githubUrl != null && project.githubUrl!.isNotEmpty) {
        map['githubUrl'] = project.githubUrl;
      }

      // Technologies en JSON string
      map['technologies'] = jsonEncode(project.technologies);

      final formData = FormData.fromMap(map);

      final response = await _apiClient.dio.put(
        '${ApiEndpoints.projectUpdate}$id',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return ProjectModel.fromJson(data);
      }

      throw Exception('Échec de la mise à jour du projet');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Supprimer un projet
  Future<void> delete(String id) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiEndpoints.projectDelete}$id',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Échec de la suppression du projet');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
            'Délai de connexion dépassé. Vérifiez votre connexion internet.');
      case DioExceptionType.badResponse:
        String message;
        try {
          final responseData = e.response?.data;
          if (responseData is Map) {
            if (responseData['error'] is Map &&
                responseData['error']['message'] != null) {
              message = responseData['error']['message'].toString();
            } else if (responseData['message'] != null) {
              message = responseData['message'].toString();
            } else if (responseData['error'] is String) {
              message = responseData['error'].toString();
            } else {
              message = 'Erreur serveur (${e.response?.statusCode})';
            }
          } else if (responseData is String) {
            message = responseData;
          } else {
            message = 'Erreur serveur (${e.response?.statusCode})';
          }
        } catch (_) {
          message = 'Une erreur est survenue';
        }
        return Exception(message);
      case DioExceptionType.cancel:
        return Exception('Requête annulée');
      case DioExceptionType.connectionError:
        return Exception('Aucune connexion internet');
      default:
        return Exception('Une erreur inattendue est survenue');
    }
  }
}
