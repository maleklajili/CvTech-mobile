import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/notification_model.dart';

class NotificationRepository {
  final ApiClient _apiClient;

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
    );
    final data = response.data;
    final list = _extractList(data, 'notifications');
    return list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.notificationsUnreadCount,
    );
    final data = response.data;
    if (data is Map) {
      final nested = data['data'] ?? data;
      if (nested is Map) {
        return _toInt(nested['unreadCount']);
      }
    }
    return 0;
  }

  /// Get unread notifications list
  Future<List<NotificationModel>> getUnreadNotifications() async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.notificationsUnreadList,
    );
    final data = response.data;
    final list = _extractList(data, null);
    return list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Mark a single notification as read
  Future<bool> markAsRead(String notificationId) async {
    final response = await _apiClient.dio.put(
      '${ApiEndpoints.notifications}/$notificationId/read',
    );
    final data = response.data;
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
    );
    return response.statusCode == 200;
  }

  /// Delete a single notification
  Future<bool> deleteNotification(String notificationId) async {
    final response = await _apiClient.dio.delete(
      '${ApiEndpoints.notifications}/$notificationId',
    );
    return response.statusCode == 200;
  }

  /// Delete all notifications
  Future<bool> deleteAllNotifications() async {
    final response = await _apiClient.dio.delete(
      ApiEndpoints.notifications,
    );
    return response.statusCode == 200;
  }

  // Helpers

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
