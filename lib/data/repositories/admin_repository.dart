import 'package:dio/dio.dart';
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/admin/admin_stats.dart';
import 'package:cv_tech/data/models/admin/report_model.dart';
import 'package:cv_tech/data/models/admin/pending_payment.dart';
import 'package:cv_tech/data/models/admin/moderation_models.dart';

class AdminRepository {
  final ApiClient _apiClient;

  AdminRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // ── Dashboard ───────────────────────────────────────────────────────

  Future<AdminStats> getStats() async {
    final response = await _apiClient.dio.get(ApiEndpoints.adminStats);
    final data = _extractData(response.data);
    return AdminStats.fromJson(data);
  }

  Future<List<ActivityDay>> getActivity() async {
    final response = await _apiClient.dio.get(ApiEndpoints.adminActivity);
    final data = _extractData(response.data);
    if (data is List) {
      return data.map((e) => ActivityDay.fromJson(e)).toList();
    }
    return [];
  }

  Future<CoinsStats> getCoinsStats() async {
    final response = await _apiClient.dio.get(ApiEndpoints.adminCoinsStats);
    final data = _extractData(response.data);
    return CoinsStats.fromJson(data);
  }

  Future<TopStats> getTopStats() async {
    final response = await _apiClient.dio.get(ApiEndpoints.adminTopStats);
    final data = _extractData(response.data);
    return TopStats.fromJson(data);
  }

  // ── Reports / Moderation ────────────────────────────────────────────

  Future<ReportStats> getReportStats() async {
    final response = await _apiClient.dio.get(ApiEndpoints.reportStats);
    final data = _extractData(response.data);
    return ReportStats.fromJson(data);
  }

  Future<List<ReportModel>> getReports({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) params['status'] = status;

    final response = await _apiClient.dio.get(
      ApiEndpoints.reports,
      queryParameters: params,
    );
    final data = _extractData(response.data);
    if (data is List) {
      return data.map((e) => ReportModel.fromJson(e)).toList();
    }
    // Sometimes paginated response puts items in 'reports' key
    if (data is Map && data['reports'] is List) {
      return (data['reports'] as List)
          .map((e) => ReportModel.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<void> updateReportStatus(
    String reportId, {
    required String status,
    String? resolutionNotes,
  }) async {
    await _apiClient.dio.put(
      '${ApiEndpoints.reportUpdateStatus}$reportId/status',
      data: {
        'status': status,
        if (resolutionNotes != null) 'resolutionNotes': resolutionNotes,
      },
    );
  }

  Future<void> deleteReport(String reportId) async {
    await _apiClient.dio.delete('${ApiEndpoints.reportDelete}$reportId');
  }

  // ── Payments ────────────────────────────────────────────────────────

  Future<List<PendingPayment>> getPendingPayments() async {
    final response = await _apiClient.dio.get(ApiEndpoints.paymentPending);
    final data = _extractData(response.data);
    if (data is List) {
      return data.map((e) => PendingPayment.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> approvePayment(String paymentId, {String? note}) async {
    await _apiClient.dio.put(
      '${ApiEndpoints.paymentApprove}$paymentId/approve',
      data: {if (note != null) 'note': note},
    );
  }

  Future<void> rejectPayment(String paymentId, {String? note}) async {
    await _apiClient.dio.put(
      '${ApiEndpoints.paymentReject}$paymentId/reject',
      data: {if (note != null) 'note': note},
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  dynamic _extractData(dynamic responseData) {
    if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'];
    }
    return responseData;
  }

  // ── Moderation ──────────────────────────────────────────────────────

  Future<ModerationStats> getModerationStats() async {
    final response =
        await _apiClient.dio.get(ApiEndpoints.moderationStats);
    final data = _extractData(response.data);
    return ModerationStats.fromJson(data);
  }

  Future<List<FlaggedPost>> getFlaggedPosts() async {
    final response =
        await _apiClient.dio.get(ApiEndpoints.moderationFlaggedPosts);
    final data = _extractData(response.data);
    if (data is Map && data['posts'] is List) {
      return (data['posts'] as List)
          .map((e) => FlaggedPost.fromJson(e))
          .toList();
    }
    if (data is List) {
      return data.map((e) => FlaggedPost.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<FlaggedUser>> getFlaggedUsers() async {
    final response =
        await _apiClient.dio.get(ApiEndpoints.moderationFlaggedUsers);
    final data = _extractData(response.data);
    if (data is Map && data['users'] is List) {
      return (data['users'] as List)
          .map((e) => FlaggedUser.fromJson(e))
          .toList();
    }
    if (data is List) {
      return data.map((e) => FlaggedUser.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> approvePost(String postId) async {
    await _apiClient.dio
        .put('${ApiEndpoints.moderationPostApprove}$postId/approve');
  }

  Future<void> rejectPost(String postId) async {
    await _apiClient.dio
        .put('${ApiEndpoints.moderationPostReject}$postId/reject');
  }

  Future<void> banUser(String userId, {String? reason}) async {
    await _apiClient.dio.put(
      '${ApiEndpoints.moderationUserBan}$userId/ban',
      data: {if (reason != null) 'reason': reason},
    );
  }

  Future<void> unbanUser(String userId) async {
    await _apiClient.dio
        .put('${ApiEndpoints.moderationUserUnban}$userId/unban');
  }

  Future<List<FlaggedUser>> getBannedUsers() async {
    final response =
        await _apiClient.dio.get(ApiEndpoints.moderationBannedUsers);
    final data = _extractData(response.data);
    if (data is Map && data['users'] is List) {
      return (data['users'] as List)
          .map((e) => FlaggedUser.fromJson(e))
          .toList();
    }
    if (data is List) {
      return data.map((e) => FlaggedUser.fromJson(e)).toList();
    }
    return [];
  }

  // ── Companies ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCompanies({
    String? status,
    String? verificationStatus,
  }) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    if (verificationStatus != null) {
      params['verificationStatus'] = verificationStatus;
    }
    final response = await _apiClient.dio.get(
      ApiEndpoints.companyVerificationRequests,
      queryParameters: params,
    );
    final data = _extractData(response.data);
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map && data['companies'] is List) {
      return (data['companies'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> verifyCompany(
    String companyId, {
    required String status,
    String? notes,
  }) async {
    await _apiClient.dio.put(
      '${ApiEndpoints.companyVerify}$companyId',
      data: {
        'status': status,
        if (notes != null) 'notes': notes,
      },
    );
  }
}
