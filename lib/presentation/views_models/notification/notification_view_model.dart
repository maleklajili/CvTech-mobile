import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cv_tech/core/base/safe_change_notifier.dart';
import 'package:cv_tech/data/models/notification_model.dart';
import 'package:cv_tech/data/repositories/notification_repository.dart';

enum NotificationState { initial, loading, loaded, error, loadingMore }

class NotificationViewModel extends SafeChangeNotifier {
  final NotificationRepository _repository;

  NotificationViewModel({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepository();

  NotificationState _state = NotificationState.initial;
  NotificationState get state => _state;

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _currentPage = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  Timer? _pollTimer;

  // Exponential backoff tracking
  int _consecutiveFailures = 0;
  static const int _maxFailures = 5;
  static const Duration _baseInterval = Duration(seconds: 60);
  static const Duration _maxInterval = Duration(minutes: 5);

  Duration get _currentInterval {
    if (_consecutiveFailures <= 0) return _baseInterval;
    final factor = 1 << _consecutiveFailures.clamp(0, 4); // 1,2,4,8,16
    final ms = _baseInterval.inMilliseconds * factor;
    return Duration(milliseconds: ms.clamp(0, _maxInterval.inMilliseconds));
  }

  /// Load notifications (initial / refresh)
  Future<void> loadNotifications() async {
    _state = NotificationState.loading;
    _currentPage = 1;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _repository.getNotifications(page: 1, limit: 20);
      _notifications = results;
      _hasMore = results.length >= 20;
      _state = NotificationState.loaded;
      _consecutiveFailures = 0;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _state = NotificationState.error;
      if (kDebugMode) print('Notification error: $e');
    }
    notifyListeners();
  }

  /// Load more (pagination)
  Future<void> loadMore() async {
    if (_state == NotificationState.loadingMore || !_hasMore) return;
    _state = NotificationState.loadingMore;
    notifyListeners();

    try {
      _currentPage++;
      final results =
          await _repository.getNotifications(page: _currentPage, limit: 20);
      _notifications.addAll(results);
      _hasMore = results.length >= 20;
      _state = NotificationState.loaded;
    } catch (e) {
      _currentPage--;
      _state = NotificationState.loaded;
      if (kDebugMode) print('Load more notifications error: $e');
    }
    notifyListeners();
  }

  /// Fetch unread count only (lightweight — used by AppBar badge)
  Future<void> fetchUnreadCount() async {
    try {
      _unreadCount = await _repository.getUnreadCount();
      _consecutiveFailures = 0;
      notifyListeners();
    } catch (_) {
      // Silently track failures; suppress log after max threshold to avoid spam.
      _consecutiveFailures++;
    }
  }

  /// Mark single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final success = await _repository.markAsRead(notificationId);
      if (success) {
        final idx = _notifications.indexWhere((n) => n.id == notificationId);
        if (idx != -1) {
          final old = _notifications[idx];
          _notifications[idx] = NotificationModel(
            id: old.id,
            userId: old.userId,
            type: old.type,
            fromUser: old.fromUser,
            relatedContent: old.relatedContent,
            contentType: old.contentType,
            title: old.title,
            description: old.description,
            read: true,
            readAt: DateTime.now(),
            action: old.action,
            actionUrl: old.actionUrl,
            metadata: old.metadata,
            createdAt: old.createdAt,
            updatedAt: old.updatedAt,
            fromUserName: old.fromUserName,
            fromUserPhoto: old.fromUserPhoto,
          );
          if (_unreadCount > 0) _unreadCount--;
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) print('Mark as read error: $e');
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    try {
      final success = await _repository.markAllAsRead();
      if (success) {
        _notifications = _notifications
            .map((n) => NotificationModel(
                  id: n.id,
                  userId: n.userId,
                  type: n.type,
                  fromUser: n.fromUser,
                  relatedContent: n.relatedContent,
                  contentType: n.contentType,
                  title: n.title,
                  description: n.description,
                  read: true,
                  readAt: DateTime.now(),
                  action: n.action,
                  actionUrl: n.actionUrl,
                  metadata: n.metadata,
                  createdAt: n.createdAt,
                  updatedAt: n.updatedAt,
                  fromUserName: n.fromUserName,
                  fromUserPhoto: n.fromUserPhoto,
                ))
            .toList();
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('Mark all read error: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final success = await _repository.deleteNotification(notificationId);
      if (success) {
        final removed =
            _notifications.firstWhere((n) => n.id == notificationId);
        _notifications.removeWhere((n) => n.id == notificationId);
        if (!removed.read && _unreadCount > 0) _unreadCount--;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('Delete notification error: $e');
    }
  }

  /// Start polling unread count with a configurable initial delay
  /// and adaptive backoff on repeated failures.
  void startPolling({
    Duration initialDelay = const Duration(seconds: 5),
  }) {
    _pollTimer?.cancel();
    // Delay the first fetch so the app can establish the connection first
    Future.delayed(initialDelay, () {
      if (!_disposed) {
        _schedulePoll();
      }
    });
  }

  void _schedulePoll() {
    if (_disposed) return;
    fetchUnreadCount().then((_) {
      if (_disposed) return;
      // Only schedule next poll if failures are below max threshold
      if (_consecutiveFailures < _maxFailures) {
        _pollTimer = Timer(_currentInterval, _schedulePoll);
      }
      // If too many failures, stop polling silently until app restarts
    });
  }

  /// Resume polling (reset failure count and restart)
  void resumePolling() {
    _consecutiveFailures = 0;
    startPolling(initialDelay: Duration.zero);
  }

  /// Stop polling
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // ignore: prefer_final_fields
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    super.dispose();
  }
}
