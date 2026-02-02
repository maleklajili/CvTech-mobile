// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:dio/dio.dart';

// Project imports:
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/profile/skill_model.dart';

class SkillRepository {
  final ApiClient _apiClient;

  SkillRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Récupérer toutes les compétences de l'utilisateur
  Future<List<SkillModel>> getAll({String? category}) async {
    try {
      final queryParams = category != null ? {'category': category} : null;
      final response = await _apiClient.dio.get(
        ApiEndpoints.skillGetAll,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        if (data is List) {
          return data.map((e) => SkillModel.fromJson(e)).toList();
        }
      }

      throw Exception('Échec de la récupération des compétences');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Récupérer une compétence par ID
  Future<SkillModel> getById(String id) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.skillById}$id',
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return SkillModel.fromJson(data);
      }

      throw Exception('Compétence non trouvée');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Créer une nouvelle compétence
  Future<SkillModel> create(SkillModel skill) async {
    try {
      final map = <String, dynamic>{};

      // Champs de base
      map['name'] = skill.name;
      map['categorie'] = skill.categorie;
      map['sousCategorie'] = skill.sousCategorie;

      // Champs optionnels
      if (skill.level != null) {
        map['level'] = skill.level!.name;
      }
      if (skill.description != null && skill.description!.isNotEmpty) {
        map['description'] = skill.description;
      }
      if (skill.color != null) {
        map['color'] = skill.color;
      }
      if (skill.percentage != null) {
        map['percentage'] = skill.percentage.toString();
      }
      if (skill.certifed != null) {
        map['certifed'] = skill.certifed.toString();
      }
      if (skill.favorite != null) {
        map['favorite'] = skill.favorite.toString();
      }
      if (skill.apprenticeship != null) {
        map['apprenticeship'] = skill.apprenticeship.toString();
      }

      // Certifications en JSON string
      map['certifications'] = jsonEncode(skill.certifications);

      final formData = FormData.fromMap(map);

      final response = await _apiClient.dio.post(
        ApiEndpoints.skillCreate,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return SkillModel.fromJson(data);
      }

      throw Exception('Échec de la création de la compétence');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Mettre à jour une compétence
  Future<SkillModel> update(String id, SkillModel skill) async {
    try {
      final map = <String, dynamic>{};

      // Champs de base
      map['name'] = skill.name;
      map['categorie'] = skill.categorie;
      map['sousCategorie'] = skill.sousCategorie;

      // Champs optionnels
      if (skill.level != null) {
        map['level'] = skill.level!.name;
      }
      if (skill.description != null && skill.description!.isNotEmpty) {
        map['description'] = skill.description;
      }
      if (skill.color != null) {
        map['color'] = skill.color;
      }
      if (skill.percentage != null) {
        map['percentage'] = skill.percentage.toString();
      }
      if (skill.certifed != null) {
        map['certifed'] = skill.certifed.toString();
      }
      if (skill.favorite != null) {
        map['favorite'] = skill.favorite.toString();
      }
      if (skill.apprenticeship != null) {
        map['apprenticeship'] = skill.apprenticeship.toString();
      }

      // Certifications en JSON string
      map['certifications'] = jsonEncode(skill.certifications);

      final formData = FormData.fromMap(map);

      final response = await _apiClient.dio.put(
        '${ApiEndpoints.skillUpdate}$id',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return SkillModel.fromJson(data);
      }

      throw Exception('Échec de la mise à jour de la compétence');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Supprimer une compétence
  Future<void> delete(String id) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiEndpoints.skillDelete}$id',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Échec de la suppression de la compétence');
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
