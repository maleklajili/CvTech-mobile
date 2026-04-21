import 'dart:async';

// Project imports:
import 'package:cv_tech/data/repositories/connection_repository.dart';
import 'package:cv_tech/data/repositories/message_repository.dart';
import 'package:cv_tech/presentation/views_models/main/interfaces/main_interfaces.dart';
import 'scroll_listener.dart';

class BottomNavigationBarViewModel extends ScrollListener
    implements IBottomNavigationBar {
  final MessageRepository _messageRepository;
  final ConnectionRepository _connectionRepository;
  Timer? _badgeTimer;
  bool _disposed = false;

  int _networkCount = 0;
  int _unreadMessages = 0;

  BottomNavigationBarViewModel(super.context)
      : _messageRepository = MessageRepository(),
        _connectionRepository = ConnectionRepository() {
    initScrollListener();
    // Delay first badge refresh to avoid flooding backend on app startup
    Future.delayed(const Duration(seconds: 2), () {
      if (!_disposed) _refreshDynamicBadges();
    });
    _startBadgeTimer();
  }

  void _startBadgeTimer() {
    _badgeTimer?.cancel();
    _badgeTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) {
        if (_disposed) return;
        _refreshDynamicBadges();
      },
    );
  }

  /// Pauses the badge polling loop. Call when the app goes to background
  /// to avoid wasting bandwidth on invisible UI.
  void pauseBadgePolling() {
    _badgeTimer?.cancel();
    _badgeTimer = null;
  }

  /// Resumes the badge polling loop. Safe to call multiple times.
  void resumeBadgePolling() {
    if (_disposed) return;
    if (_badgeTimer != null && _badgeTimer!.isActive) return;
    _refreshDynamicBadges();
    _startBadgeTimer();
  }

  int currentIndex = 0;
  int get networkCount => _networkCount;
  int get unreadMessages => _unreadMessages;

  int get bottomnavItemLenght => 5;

  Future<void> refreshBadges() => _refreshDynamicBadges();

  Future<void> _refreshDynamicBadges() async {
    try {
      final chats = await _messageRepository.getRecentChats();
      final unread = chats.fold<int>(
        0,
        (sum, c) => sum + _safeToInt(c.unreadCount),
      );
      _unreadMessages = unread;
    } catch (_) {
      // Keep previous value if backend is temporarily unreachable.
    }

    try {
      final friends = await _connectionRepository.getFriends();
      _networkCount = friends.length;
    } catch (_) {
      // Keep previous value if backend is temporarily unreachable.
    }

    _safeUpdate();
  }

  int _safeToInt(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  void _safeUpdate() {
    if (!_disposed) {
      update();
    }
  }

  @override
  void changeCurrentIndex(int index) {
    currentIndex = index;
    _safeUpdate();
  }

  @override
  void dispose() {
    _disposed = true;
    _badgeTimer?.cancel();
    scrollController.dispose();
    super.dispose();
  }
}
