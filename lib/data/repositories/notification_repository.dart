import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/notification_model.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  // Reusable option: receive raw text, never auto-decode JSON
  static final _plainOpts = Options(responseType: ResponseType.plain);

  NotificationRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Get paginated notifications
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final skip = (page - 1) * limit;
    final response = await _apiClient.dio.get(
      ApiEndpoints.notifications,
      queryParameters: {'take': limit, 'skip': skip},
      options: _plainOpts,
    );
    final data = _safeDecodeJson(response.data);
    final list = _extractList(data, 'notifications');
    return list
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.notificationsUnreadCount,
      options: _plainOpts,
    );
    final data = _safeDecodeJson(response.data);
    if (data is Map) {
      final nested = data['data'] ?? data;
      if (nested is Map) return _toInt(nested['unreadCount']);
    }
    return 0;
  }

  /// Get unread notifications list
  Future<List<NotificationModel>> getUnreadNotifications() async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.notificationsUnreadList,
      options: _plainOpts,
    );
    final data = _safeDecodeJson(response.data);
    final list = _extractList(data, null);
    return list
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();
  }

  /// Mark a single notification as read
  Future<bool> markAsRead(String notificationId) async {
    final response = await _apiClient.dio.put(
      '${ApiEndpoints.notifications}/$notificationId/read',
      options: _plainOpts,
    );
    final data = _safeDecodeJson(response.data);
    if (data is Map) {
      final nested = data['data'] ?? data;
      if (nested is Map) return nested['marked'] == true;
    }
    return response.statusCode == 200;
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.notificationMarkAllRead,
      options: _plainOpts,
    );
    return response.statusCode == 200;
  }

  /// Delete a single notification
  Future<bool> deleteNotification(String notificationId) async {
    final response = await _apiClient.dio.delete(
      '${ApiEndpoints.notifications}/$notificationId',
      options: _plainOpts,
    );
    return response.statusCode == 200;
  }

  /// Delete all notifications
  Future<bool> deleteAllNotifications() async {
    final response = await _apiClient.dio.delete(
      ApiEndpoints.notifications,
      options: _plainOpts,
    );
    return response.statusCode == 200;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Safely decodes a JSON string. Returns null instead of throwing on
  /// empty bodies, HTML error pages, or any other non-JSON content.
  dynamic _safeDecodeJson(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map || raw is List) return raw; // already decoded
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  List<dynamic> _extractList(dynamic data, String? key) {
    if (data is Map) {
      if (key != null && data['data'] is Map && data['data'][key] is List) {
        return data['data'][key] as List;
      }
      if (key != null && data[key] is List) return data[key] as List;
      final nested = data['data'];
      if (nested is List) return nested;
      if (nested is Map && key != null && nested[key] is List) {
        return nested[key] as List;
      }
    }
    if (data is List) return data;
    return [];
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
