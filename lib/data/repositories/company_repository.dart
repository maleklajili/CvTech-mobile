// Dart imports:
import 'dart:io';

// Package imports:
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

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

  /// Créer une nouvelle entreprise (with optional verification docs and images)
  Future<CompanyModel> create(CompanyModel company, {List<PlatformFile>? verificationDocs, PlatformFile? logo, PlatformFile? coverImage}) async {
    try {
      final formData = _toCompanyFormData(company, verificationDocs: verificationDocs, logo: logo, coverImage: coverImage);

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

  /// Mettre à jour une entreprise (with optional verification docs and images)
  Future<CompanyModel> update(String id, CompanyModel company, {List<PlatformFile>? verificationDocs, PlatformFile? logo, PlatformFile? coverImage}) async {
    try {
      final formData = _toCompanyFormData(company, verificationDocs: verificationDocs, logo: logo, coverImage: coverImage);

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
      final data = error.response!.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? data['error'] ?? 'Une erreur est survenue';
        return Exception(message.toString());
      }
      return Exception(data.toString());
    }
    return Exception(error.message ?? 'Erreur de connexion');
  }

  FormData _toCompanyFormData(CompanyModel company, {List<PlatformFile>? verificationDocs, PlatformFile? logo, PlatformFile? coverImage}) {
    final formData = FormData();

    formData.fields
      ..add(MapEntry('name', company.name))
      ..add(MapEntry('industry', company.industry))
      ..add(MapEntry('description', company.description))
      ..add(MapEntry('website', (company.website ?? '').trim()))
      ..add(MapEntry('location', (company.location ?? '').trim()))
      ..add(MapEntry('status', company.status.name));

    if ((company.shortDescription ?? '').trim().isNotEmpty) {
      formData.fields.add(MapEntry('shortDescription', company.shortDescription!.trim()));
    }
    if (company.foundedYear != null) {
      formData.fields.add(MapEntry('foundedYear', company.foundedYear.toString()));
    }
    if ((company.size ?? '').trim().isNotEmpty) {
      formData.fields.add(MapEntry('size', company.size!.trim()));
    }
    if ((company.address ?? '').trim().isNotEmpty) {
      formData.fields.add(MapEntry('address', company.address!.trim()));
    }
    if ((company.phone ?? '').trim().isNotEmpty) {
      formData.fields.add(MapEntry('phone', company.phone!.trim()));
    }
    if ((company.email ?? '').trim().isNotEmpty) {
      formData.fields.add(MapEntry('email', company.email!.trim()));
    }

    final social = company.socialMedia;
    if (social != null) {
      if ((social.linkedin ?? '').trim().isNotEmpty) {
        formData.fields.add(MapEntry('socialMedia.linkedin', social.linkedin!.trim()));
      }
      if ((social.twitter ?? '').trim().isNotEmpty) {
        formData.fields.add(MapEntry('socialMedia.twitter', social.twitter!.trim()));
      }
      if ((social.facebook ?? '').trim().isNotEmpty) {
        formData.fields.add(MapEntry('socialMedia.facebook', social.facebook!.trim()));
      }
      if ((social.instagram ?? '').trim().isNotEmpty) {
        formData.fields.add(MapEntry('socialMedia.instagram', social.instagram!.trim()));
      }
    }

    for (var i = 0; i < company.keywords.length; i++) {
      final keyword = company.keywords[i].trim();
      if (keyword.isNotEmpty) {
        formData.fields.add(MapEntry('keywords[$i]', keyword));
      }
    }

    // Images
    if (logo != null && logo.bytes != null) {
      formData.files.add(MapEntry(
        'logo',
        MultipartFile.fromBytes(
          logo.bytes!,
          filename: logo.name,
        ),
      ));
    }
    if (coverImage != null && coverImage.bytes != null) {
      formData.files.add(MapEntry(
        'coverImage',
        MultipartFile.fromBytes(
          coverImage.bytes!,
          filename: coverImage.name,
        ),
      ));
    }

    // Verification
    if ((company.verificationNotes ?? '').trim().isNotEmpty) {
      formData.fields.add(MapEntry('verificationNotes', company.verificationNotes!.trim()));
    }
    if (verificationDocs != null && verificationDocs.isNotEmpty) {
      formData.fields.add(MapEntry('verificationDocumentsCount', verificationDocs.length.toString()));
      for (var i = 0; i < verificationDocs.length; i++) {
        if (verificationDocs[i].bytes != null) {
          formData.files.add(MapEntry(
            'verificationDocuments_$i',
            MultipartFile.fromBytes(
              verificationDocs[i].bytes!,
              filename: verificationDocs[i].name,
            ),
          ));
        }
      }
    }

    return formData;
  }
}
