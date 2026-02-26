// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:dio/dio.dart';

// Project imports:
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/profile/experience_model.dart';

class ExperienceRepository {
  final ApiClient _apiClient;

  ExperienceRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Récupérer toutes les expériences de l'utilisateur
  Future<List<ExperienceModel>> getAll() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.experienceGetAll,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        if (data is List) {
          return data.map((e) => ExperienceModel.fromJson(e)).toList();
        }
      }

      throw Exception('Échec de la récupération des expériences');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Récupérer une expérience par ID
  Future<ExperienceModel> getById(String id) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.experienceById}$id',
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return ExperienceModel.fromJson(data);
      }

      throw Exception('Expérience non trouvée');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Créer une nouvelle expérience
  Future<ExperienceModel> create(
      ExperienceModel experience, List<List<int>>? certificateFiles) async {
    try {
      final formData = FormData();

      // Champs de base - exactement comme le frontend Next.js
      formData.fields.add(MapEntry('post', experience.post));
      formData.fields.add(MapEntry('entreprise', experience.entreprise));
      formData.fields.add(MapEntry('place', experience.place));
      formData.fields.add(MapEntry('description', experience.description));

      // Dates - format YYYY-MM-DD comme le frontend
      formData.fields.add(MapEntry(
          'startDate', experience.startDate.toIso8601String().split('T')[0]));
      // endDate vide si currentPost est true, comme le frontend
      formData.fields.add(MapEntry(
          'endDate',
          experience.currentPost
              ? ''
              : (experience.endDate?.toIso8601String().split('T')[0] ?? '')));

      // Boolean comme JSON string
      formData.fields
          .add(MapEntry('currentPost', experience.currentPost.toString()));

      // KeyAchievements
      if (experience.keyAchievements.isNotEmpty) {
        formData.fields.add(MapEntry(
            'KeyAchievements', jsonEncode(experience.keyAchievements)));
      }

      // Skills - comme des objets avec structure complète
      for (var i = 0; i < experience.skills.length; i++) {
        final skill = experience.skills[i];
        if (skill.id != null && skill.id!.isNotEmpty) {
          formData.fields.add(MapEntry('skills[$i][_id]', skill.id!));
        }
        formData.fields.add(MapEntry('skills[$i][name]', skill.name));
        formData.fields.add(MapEntry('skills[$i][category]', skill.category));
      }

      // Certificates - upload des fichiers
      if (certificateFiles != null && certificateFiles.isNotEmpty) {
        for (var i = 0; i < certificateFiles.length; i++) {
          final bytes = certificateFiles[i];
          final cert = experience.certificates.length > i
              ? experience.certificates[i]
              : null;
          final fileName =
              cert?.name ?? 'certificate_$i.${cert?.type ?? 'pdf'}';
          formData.files.add(MapEntry(
            'certificates',
            MultipartFile.fromBytes(bytes, filename: fileName),
          ));
        }
      }

      final response = await _apiClient.dio.post(
        ApiEndpoints.experienceCreate,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return ExperienceModel.fromJson(data);
      }

      throw Exception('Échec de la création de l\'expérience');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Mettre à jour une expérience
  Future<ExperienceModel> update(
    String id,
    ExperienceModel experience,
    List<List<int>>? certificateFiles,
    List<String>? filesToDelete,
  ) async {
    try {
      final formData = FormData();

      // Champs de base - exactement comme le frontend Next.js
      formData.fields.add(MapEntry('post', experience.post));
      formData.fields.add(MapEntry('entreprise', experience.entreprise));
      formData.fields.add(MapEntry('place', experience.place));
      formData.fields.add(MapEntry('description', experience.description));

      // Dates - format YYYY-MM-DD comme le frontend
      formData.fields.add(MapEntry(
          'startDate', experience.startDate.toIso8601String().split('T')[0]));
      // endDate vide si currentPost est true, comme le frontend
      formData.fields.add(MapEntry(
          'endDate',
          experience.currentPost
              ? ''
              : (experience.endDate?.toIso8601String().split('T')[0] ?? '')));

      // Boolean comme JSON string
      formData.fields
          .add(MapEntry('currentPost', experience.currentPost.toString()));

      // KeyAchievements
      if (experience.keyAchievements.isNotEmpty) {
        formData.fields.add(MapEntry(
            'KeyAchievements', jsonEncode(experience.keyAchievements)));
      }

      // Skills - comme des objets avec structure complète
      for (var i = 0; i < experience.skills.length; i++) {
        final skill = experience.skills[i];
        if (skill.id != null && skill.id!.isNotEmpty) {
          formData.fields.add(MapEntry('skills[$i][_id]', skill.id!));
        }
        formData.fields.add(MapEntry('skills[$i][name]', skill.name));
        formData.fields.add(MapEntry('skills[$i][category]', skill.category));
      }

      // Certificates à supprimer
      if (filesToDelete != null && filesToDelete.isNotEmpty) {
        formData.fields
            .add(MapEntry('filesToDelete', jsonEncode(filesToDelete)));
      }

      // Nouveaux certificates - upload des fichiers
      if (certificateFiles != null && certificateFiles.isNotEmpty) {
        for (var i = 0; i < certificateFiles.length; i++) {
          final bytes = certificateFiles[i];
          final cert = experience.certificates.firstWhere(
            (c) => c.bytes != null,
            orElse: () => experience.certificates[i],
          );
          final fileName = cert.name;
          formData.files.add(MapEntry(
            'certificates',
            MultipartFile.fromBytes(bytes, filename: fileName),
          ));
        }
      }

      final response = await _apiClient.dio.put(
        '${ApiEndpoints.experienceUpdate}$id',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return ExperienceModel.fromJson(data);
      }

      throw Exception('Échec de la mise à jour de l\'expérience');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Supprimer une expérience
  Future<void> delete(String id) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiEndpoints.experienceDelete}$id',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Échec de la suppression de l\'expérience');
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
