import 'package:dio/dio.dart';
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/job_match_model.dart';

class JobMatchRepository {
  final ApiClient _apiClient;

  JobMatchRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Fetch AI-matched job offers for the authenticated user.
  Future<List<JobMatchModel>> getMatches() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.jobMatches);

      if (response.statusCode == 200) {
        final body = response.data;
        final rawList = body is Map && body.containsKey('data')
            ? body['data']
            : body;

        if (rawList is List) {
          return rawList
              .map((e) => JobMatchModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      throw Exception('Impossible de récupérer les offres correspondantes');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? e.toString();
      throw Exception(msg);
    }
  }

  /// Save swipe decision — on accept we submit a job application.
  Future<void> swipeAccept(String jobId) async {
    try {
      await _apiClient.dio.post(
        '${ApiEndpoints.jobApplications}/apply/$jobId',
      );
    } on DioException {
      // Swipe-apply is best-effort — silently ignore network errors
    }
  }
}
