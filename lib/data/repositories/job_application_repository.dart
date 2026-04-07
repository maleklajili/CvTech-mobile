import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io';

import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';

class JobApplicationRepository {
  final ApiClient _apiClient;

  JobApplicationRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  String? _asObjectIdString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is Map) {
      final oid = value[r'$oid'] ?? value['_id'] ?? value['id'];
      return _asObjectIdString(oid);
    }
    return value.toString();
  }

  List<Map<String, dynamic>> _extractList(dynamic data) {
    dynamic source = data;
    if (source is Map<String, dynamic>) {
      if (source['data'] is Map<String, dynamic>) {
        final nested = source['data'] as Map<String, dynamic>;
        source = nested['data'] ?? nested['items'] ?? nested['applications'] ?? nested;
      } else {
        source = source['data'] ?? source['items'] ?? source['applications'] ?? source;
      }
    }

    if (source is List) {
      return source
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> applyForJob({
    required String jobId,
    required String coverLetter,
    String? cvPath,
    List<int>? cvBytes,
    String? cvFileName,
  }) async {
    try {
      final formMap = <String, dynamic>{
        'coverLetter': coverLetter,
      };

      if (cvBytes != null && cvBytes.isNotEmpty) {
        final name = cvFileName ?? 'cv.pdf';
        formMap['cv'] = MultipartFile.fromBytes(
          cvBytes,
          filename: name,
          contentType: _mimeFromName(name),
        );
      } else if (cvPath != null && cvPath.isNotEmpty) {
        final name = cvFileName ?? cvPath.split(Platform.pathSeparator).last;
        formMap['cv'] = await MultipartFile.fromFile(
          cvPath,
          filename: name,
          contentType: _mimeFromName(name),
        );
      }

      final response = await _apiClient.dio.post(
        '${ApiEndpoints.jobApplications}/apply/$jobId',
        data: FormData.fromMap(formMap),
      );

      final body = response.data;
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          return data;
        }
        return body;
      }

      throw Exception('Reponse candidature invalide');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getCompanyApplications({
    required String companyId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.jobApplications}/company-applications',
        queryParameters: {'companyId': companyId},
      );

      final list = _extractList(response.data);
      return list.map((item) {
        final normalized = Map<String, dynamic>.from(item);
        normalized['_id'] = _asObjectIdString(item['_id']) ?? item['_id'];
        normalized['jobId'] = _asObjectIdString(item['jobId']) ?? item['jobId'];
        normalized['companyId'] = _asObjectIdString(item['companyId']) ?? item['companyId'];
        normalized['userId'] = _asObjectIdString(item['userId']) ?? item['userId'];
        return normalized;
      }).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMyApplications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.jobApplications}/my-applications',
        queryParameters: {'page': page, 'limit': limit},
      );

      final list = _extractList(response.data);
      return list.map((item) {
        final normalized = Map<String, dynamic>.from(item);
        normalized['_id'] = _asObjectIdString(item['_id']) ?? item['_id'];
        normalized['jobId'] = _asObjectIdString(item['jobId']) ?? item['jobId'];
        normalized['companyId'] = _asObjectIdString(item['companyId']) ?? item['companyId'];
        normalized['userId'] = _asObjectIdString(item['userId']) ?? item['userId'];
        return normalized;
      }).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> updateApplicationStatus({
    required String applicationId,
    required String companyId,
    required String status,
    String? feedback,
  }) async {
    try {
      final payload = <String, dynamic>{'status': status};
      if (feedback != null && feedback.trim().isNotEmpty) {
        payload['feedback'] = feedback.trim();
      }

      await _apiClient.dio.put(
        '${ApiEndpoints.jobApplication}$applicationId/status',
        queryParameters: {'companyId': companyId},
        data: payload,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> withdrawApplication({
    required String applicationId,
  }) async {
    try {
      await _apiClient.dio.put(
        '${ApiEndpoints.jobApplication}$applicationId/withdraw',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> respondToApplication({
    required String applicationId,
    required String companyId,
    required String response,
  }) async {
    try {
      await _apiClient.dio.put(
        '${ApiEndpoints.jobApplication}$applicationId/respond',
        queryParameters: {'companyId': companyId},
        data: {'response': response},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<String> downloadApplicationCv({
    required String applicationId,
    String fallbackFileName = 'cv.pdf',
  }) async {
    try {
      final response = await _apiClient.dio.get<List<int>>(
        '${ApiEndpoints.jobApplication}$applicationId/download-cv',
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Fichier CV vide');
      }

      final disposition = response.headers.value('content-disposition');
      final parsedName = _extractFileNameFromDisposition(disposition);
      final safeName = _safeFileName(parsedName ?? fallbackFileName);
      final file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}${DateTime.now().millisecondsSinceEpoch}_$safeName',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  String? _extractFileNameFromDisposition(String? disposition) {
    if (disposition == null || disposition.isEmpty) return null;

    final fileNameStar = RegExp(r"filename\*=UTF-8''([^;]+)", caseSensitive: false)
        .firstMatch(disposition)
        ?.group(1);
    if (fileNameStar != null && fileNameStar.isNotEmpty) {
      return Uri.decodeComponent(fileNameStar).replaceAll('"', '').trim();
    }

    final fileName = RegExp(r'filename="?([^";]+)"?', caseSensitive: false)
        .firstMatch(disposition)
        ?.group(1);
    if (fileName != null && fileName.isNotEmpty) {
      return Uri.decodeComponent(fileName).replaceAll('"', '').trim();
    }
    return null;
  }

  String _safeFileName(String value) {
    final trimmed = value.trim();
    final fallback = trimmed.isEmpty ? 'cv.pdf' : trimmed;
    return fallback.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  static MediaType _mimeFromName(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'doc':
        return MediaType('application', 'msword');
      case 'docx':
        return MediaType('application',
            'vnd.openxmlformats-officedocument.wordprocessingml.document');
      default:
        return MediaType('application', 'pdf');
    }
  }

  Exception _handleDioError(DioException error) {
    if (error.response?.data != null && error.response?.data is Map) {
      final data = error.response!.data as Map;
      final message = data['message'] ?? data['error'] ?? 'Une erreur est survenue';
      return Exception(message.toString());
    }
    return Exception(error.message ?? 'Erreur de connexion');
  }

  /// Returns applicants for a job ranked by NLP TF-IDF match score (descending).
  Future<List<Map<String, dynamic>>> getRankedCandidates({
    required String jobId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.jobApplications}/job/$jobId/ranked-candidates',
      );

      final list = _extractList(response.data);
      return list.map((item) {
        final normalized = Map<String, dynamic>.from(item);
        normalized['_id'] = _asObjectIdString(item['_id']) ?? item['_id'];
        normalized['jobId'] = _asObjectIdString(item['jobId']) ?? item['jobId'];
        normalized['userId'] = _asObjectIdString(item['userId']) ?? item['userId'];
        normalized['score'] = (item['score'] as num?)?.toInt();
        return normalized;
      }).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
}
