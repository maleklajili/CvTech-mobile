// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:dio/dio.dart';

// Project imports:
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/profile/education_model.dart';

class EducationRepository {
  final ApiClient _apiClient;

  EducationRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Récupérer toutes les formations de l'utilisateur
  Future<List<EducationModel>> getAll({String? type}) async {
    try {
      final queryParams = type != null ? {'type': type} : null;
      final response = await _apiClient.dio.get(
        ApiEndpoints.educationGetAll,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        if (data is List) {
          return data.map((e) => EducationModel.fromJson(e)).toList();
        }
      }

      throw Exception('Échec de la récupération des formations');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Récupérer une formation par ID
  Future<EducationModel> getById(String id) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.educationById}$id',
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return EducationModel.fromJson(data);
      }

      throw Exception('Formation non trouvée');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Créer une nouvelle formation
  Future<EducationModel> create(
      EducationModel education, List<List<int>>? certificateFiles) async {
    try {
      final formData = FormData();

      // Champs de base - exactement comme le frontend Next.js
      formData.fields.add(MapEntry('degree', education.degree));
      formData.fields.add(MapEntry('school', education.school));
      formData.fields.add(MapEntry('location', education.location));
      formData.fields.add(MapEntry('type', education.type.name));
      formData.fields.add(MapEntry('description', education.description));

      // Dates - format YYYY-MM-DD comme le frontend
      formData.fields.add(MapEntry(
          'startDate', education.startDate.toIso8601String().split('T')[0]));
      formData.fields.add(MapEntry(
          'endDate',
          education.current
              ? ''
              : (education.endDate?.toIso8601String().split('T')[0] ?? '')));

      // Booleans comme JSON string
      formData.fields.add(MapEntry('current', education.current.toString()));
      formData.fields
          .add(MapEntry('featured', (education.featured ?? false).toString()));

      // Champs optionnels
      if (education.grade != null && education.grade!.isNotEmpty) {
        formData.fields.add(MapEntry('grade', education.grade!));
      }
      if (education.url != null && education.url!.isNotEmpty) {
        formData.fields.add(MapEntry('url', education.url!));
      }
      if (education.color != null) {
        formData.fields.add(MapEntry('color', education.color!));
      }
      if (education.icon != null) {
        formData.fields.add(MapEntry('icon', education.icon!));
      }
      if (education.progress != null) {
        formData.fields
            .add(MapEntry('progress', education.progress.toString()));
      }
      if (education.level != null) {
        formData.fields.add(MapEntry('level', education.level!.name));
      }
      if (education.score != null) {
        formData.fields.add(MapEntry('score', education.score.toString()));
      }

      // Tags en JSON string
      if (education.tags != null && education.tags!.isNotEmpty) {
        formData.fields.add(MapEntry('tags', jsonEncode(education.tags)));
      }

      // Skills - comme des objets avec structure complète
      for (var i = 0; i < education.skills.length; i++) {
        final skill = education.skills[i];
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
          final cert = education.certificates.length > i
              ? education.certificates[i]
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
        ApiEndpoints.educationCreate,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return EducationModel.fromJson(data);
      }

      throw Exception('Échec de la création de la formation');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Mettre à jour une formation
  Future<EducationModel> update(
    String id,
    EducationModel education,
    List<List<int>>? certificateFiles,
    List<String>? filesToDelete,
  ) async {
    try {
      final formData = FormData();

      // Champs de base - exactement comme le frontend Next.js
      formData.fields.add(MapEntry('degree', education.degree));
      formData.fields.add(MapEntry('school', education.school));
      formData.fields.add(MapEntry('location', education.location));
      formData.fields.add(MapEntry('type', education.type.name));
      formData.fields.add(MapEntry('description', education.description));

      // Dates - format YYYY-MM-DD comme le frontend
      formData.fields.add(MapEntry(
          'startDate', education.startDate.toIso8601String().split('T')[0]));
      formData.fields.add(MapEntry(
          'endDate',
          education.current
              ? ''
              : (education.endDate?.toIso8601String().split('T')[0] ?? '')));

      // Booleans comme JSON string
      formData.fields.add(MapEntry('current', education.current.toString()));
      formData.fields
          .add(MapEntry('featured', (education.featured ?? false).toString()));

      // Champs optionnels
      if (education.grade != null && education.grade!.isNotEmpty) {
        formData.fields.add(MapEntry('grade', education.grade!));
      }
      if (education.url != null && education.url!.isNotEmpty) {
        formData.fields.add(MapEntry('url', education.url!));
      }
      if (education.color != null) {
        formData.fields.add(MapEntry('color', education.color!));
      }
      if (education.icon != null) {
        formData.fields.add(MapEntry('icon', education.icon!));
      }
      if (education.progress != null) {
        formData.fields
            .add(MapEntry('progress', education.progress.toString()));
      }
      if (education.level != null) {
        formData.fields.add(MapEntry('level', education.level!.name));
      }
      if (education.score != null) {
        formData.fields.add(MapEntry('score', education.score.toString()));
      }

      // Tags en JSON string
      if (education.tags != null && education.tags!.isNotEmpty) {
        formData.fields.add(MapEntry('tags', jsonEncode(education.tags)));
      }

      // Skills - comme des objets avec structure complète
      for (var i = 0; i < education.skills.length; i++) {
        final skill = education.skills[i];
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
          final cert = education.certificates.firstWhere(
            (c) => c.bytes != null,
            orElse: () => education.certificates[i],
          );
          final fileName = cert.name;
          formData.files.add(MapEntry(
            'certificates',
            MultipartFile.fromBytes(bytes, filename: fileName),
          ));
        }
      }

      final response = await _apiClient.dio.put(
        '${ApiEndpoints.educationUpdate}$id',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        return EducationModel.fromJson(data);
      }

      throw Exception('Échec de la mise à jour de la formation');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Supprimer une formation
  Future<void> delete(String id) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiEndpoints.educationDelete}$id',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Échec de la suppression de la formation');
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
