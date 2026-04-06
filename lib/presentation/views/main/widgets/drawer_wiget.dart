import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/core/services/socket_service.dart';
import 'package:cv_tech/data/models/auth/user_model.dart';
import 'package:cv_tech/data/repositories/message_repository.dart';
import 'package:cv_tech/data/repositories/user_repository.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_bloc.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_event.dart';
import 'package:cv_tech/presentation/views/chat/chat_list_view.dart';
import 'package:cv_tech/presentation/views/community/community_hub_view.dart';
import 'package:cv_tech/presentation/views/company/companies_view.dart';
import 'package:cv_tech/presentation/views/connection/connections_view.dart';
import 'package:cv_tech/presentation/views/job/jobs_view.dart';
import 'package:cv_tech/presentation/views/main/settings_view.dart';
import 'package:cv_tech/presentation/views/main/trends_explore_view.dart';
import 'package:cv_tech/presentation/views/profile/profile_view.dart';
import 'package:cv_tech/presentation/views_models/app/theme_view_model.dart';
import 'package:cv_tech/presentation/widgets/modern_dialog.dart';
import 'package:cv_tech/theme/app_theme.dart';
import 'package:cv_tech/core/l10n/app_localizations.dart';

class DrawerWiget extends StatefulWidget {
  const DrawerWiget({
    super.key,
  });

  @override
  State<DrawerWiget> createState() => _DrawerWigetState();
}

class _DrawerWigetState extends State<DrawerWiget> {
  final UserRepository _userRepository = UserRepository();
  final MessageRepository _messageRepository = MessageRepository();
  final SocketService _socketService = SocketService.instance;

  StreamSubscription<Map<String, dynamic>>? _notificationSub;
  StreamSubscription<Map<String, dynamic>>? _messageSub;
  StreamSubscription<Map<String, dynamic>>? _networkSub;
  Timer? _badgePollingTimer;

  UserModel? _currentUser;
  bool _isLoading = true;
  int _unreadMessages = 0;
  int _unreadNotifications = 0;
  int _lastUnreadMessages = 0;
  final List<_DrawerNotificationItem> _notifications = <_DrawerNotificationItem>[];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _initDynamicBadges();
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    _messageSub?.cancel();
    _networkSub?.cancel();
    _badgePollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _userRepository.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initDynamicBadges() async {
    await _refreshUnreadMessages();

    await _socketService.connect();
    _startBadgePolling();

    _notificationSub?.cancel();
    _notificationSub = _socketService.onNotification.listen((payload) {
      if (!mounted) return;
      _appendNotification(_DrawerNotificationItem.fromPayload(payload));
    });

    _messageSub?.cancel();
    _messageSub = _socketService.onNewMessage.listen((payload) {
      _refreshUnreadMessages(notifyOnIncrease: true);
      if (!mounted) return;
      _appendNotification(_DrawerNotificationItem.fromPayload({
        'title': 'Nouveau message',
        'message': payload['text'] ?? payload['message'] ?? 'Vous avez recu un nouveau message',
        'createdAt': DateTime.now().toIso8601String(),
      }));
    });

    _networkSub?.cancel();
    _networkSub = _socketService.onConnectionRequest.listen((payload) {
      if (!mounted) return;
      _appendNotification(_DrawerNotificationItem.fromPayload({
        'title': 'Reseau',
        'message': payload['message'] ?? 'Nouvelle activite dans votre reseau',
        'createdAt': DateTime.now().toIso8601String(),
      }));
    });
  }

  void _startBadgePolling() {
    _badgePollingTimer?.cancel();
    _badgePollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _refreshUnreadMessages(notifyOnIncrease: true);
    });
  }

  void _appendNotification(_DrawerNotificationItem item) {
    if (!mounted) return;
    setState(() {
      _notifications.insert(0, item);
      _unreadNotifications = _notifications.where((n) => !n.isRead).length;
    });
  }

  Future<void> _closeDrawerIfOpen() async {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }

  Future<void> _openPage(Widget page, String routeName) async {
    await _closeDrawerIfOpen();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => page,
        settings: RouteSettings(name: routeName),
      ),
    );
  }

  Future<void> _markAllNotificationsRead() async {
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
      _unreadNotifications = 0;
    });
  }

  Future<void> _refreshUnreadMessages({bool notifyOnIncrease = false}) async {
    final previousUnread = _unreadMessages;
    final previousTracked = _lastUnreadMessages;
    final baselineUnread = previousTracked > 0 ? previousTracked : previousUnread;

    try {
      final chats = await _messageRepository.getRecentChats();
      final unread = chats.fold<int>(
        0,
        (sum, chat) => sum + _safeToInt(chat.unreadCount),
      );
      if (!mounted) return;
      setState(() {
        _unreadMessages = unread;
        _lastUnreadMessages = unread;
      });

      if (notifyOnIncrease && unread > baselineUnread) {
        final diff = unread - baselineUnread;
        _appendNotification(
          _DrawerNotificationItem(
            title: 'Messages',
            message: diff == 1
                ? 'Vous avez 1 nouveau message non lu'
                : 'Vous avez $diff nouveaux messages non lus',
            createdAt: DateTime.now(),
            isRead: false,
          ),
        );
      }
    } catch (_) {
      // Keep existing badge value if fetch fails.
    }
  }

  Future<void> _navigateToProfile() async {
    await _openPage(const ProfileView(), '/profile');
  }

  Future<void> _navigateToCommunities() async {
    await _openPage(const CommunityHubView(), '/communities');
  }

  Future<void> _navigateToCompanies() async {
    await _openPage(const CompaniesView(), '/companies');
  }

  Future<void> _navigateToJobs() async {
    await _openPage(const JobsView(), '/jobs');
  }

  Future<void> _navigateToTrends() async {
    await _openPage(const TrendsExploreView(), '/trends');
  }

  Future<void> _navigateToSettings() async {
    await _openPage(const SettingsView(), '/settings');
  }

  Future<void> _navigateToMessages() async {
    await _openPage(const ChatListView(), '/messages');
    await _refreshUnreadMessages();
  }

  Future<void> _navigateToNetwork() async {
    await _openPage(const ConnectionsView(), '/friends');
  }

  Future<void> _navigateToNotifications() async {
    await _markAllNotificationsRead();
    await _openPage(
      _NotificationsView(notifications: _notifications),
      '/notifications',
    );
  }

  int _safeToInt(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    try {
      return int.tryParse(value.toString()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  String? _badgeValue(Object? rawCount) {
    final count = _safeToInt(rawCount);
    if (count <= 0) return null;
    if (count > 99) return '99+';
    return count.toString();
  }

  List<_DrawerMenuItemConfig> _mainMenuItems() {
    final t = AppLocalizations.of(context);
    return <_DrawerMenuItemConfig>[
      _DrawerMenuItemConfig(
        title: t.home,
        icon: Icons.home,
        routeName: '/',
      ),
      _DrawerMenuItemConfig(
        title: t.explore,
        icon: Icons.explore,
        routeName: '/trends',
        onTap: _navigateToTrends,
      ),
      _DrawerMenuItemConfig(
        title: t.myNetwork,
        icon: Icons.people,
        routeName: '/friends',
        onTap: _navigateToNetwork,
      ),
      _DrawerMenuItemConfig(
        title: t.communities,
        icon: Icons.public,
        routeName: '/communities',
        onTap: _navigateToCommunities,
      ),
      _DrawerMenuItemConfig(
        title: t.messages,
        icon: Icons.message,
        routeName: '/messages',
        badge: _badgeValue(_unreadMessages),
        onTap: _navigateToMessages,
      ),
      _DrawerMenuItemConfig(
        title: t.notifications,
        icon: Icons.notifications,
        routeName: '/notifications',
        badge: _badgeValue(_unreadNotifications),
        onTap: _navigateToNotifications,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // En-tête du profil utilisateur
            _buildUserHeader(),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Créer'),
              ),
            ),
            // Coins
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE4CA)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.monetization_on,
                          color: AppColors.primaryColor),
                      SizedBox(width: 8),
                      Text(
                        'Mes coins',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Text(
                    _isLoading ? '...' : '${_currentUser?.coins ?? 0}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Menu principal
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'MENU PRINCIPAL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMutedColor,
                ),
              ),
            ),
            ..._mainMenuItems().map(
              (item) => _buildMenuItem(
                context,
                item.title,
                item.icon,
                isActive: ModalRoute.of(context)?.settings.name == item.routeName,
                badge: item.badge,
                onTap: item.onTap,
              ),
            ),
            const Divider(),
            // Professionnel
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'PROFESSIONNEL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMutedColor,
                ),
              ),
            ),
            _buildMenuItem(
              context,
              AppLocalizations.of(context).companies,
              Icons.business,
              isActive: ModalRoute.of(context)?.settings.name == '/companies',
              onTap: _navigateToCompanies,
            ),
            _buildMenuItem(
              context,
              AppLocalizations.of(context).jobOffers,
              Icons.work,
              isActive: ModalRoute.of(context)?.settings.name == '/jobs',
              onTap: _navigateToJobs,
            ),
            _buildMenuItem(
              context,
              AppLocalizations.of(context).trending,
              Icons.trending_up,
              isActive: ModalRoute.of(context)?.settings.name == '/trends',
              onTap: _navigateToTrends,
            ),
            const Divider(),
            // Utilisateur
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'UTILISATEUR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMutedColor,
                ),
              ),
            ),
            _buildMenuItem(
              context,
              AppLocalizations.of(context).profile,
              Icons.person,
              isActive: ModalRoute.of(context)?.settings.name == '/profile',
              onTap: _navigateToProfile,
            ),
            _buildMenuItem(
              context,
              'Mes coins',
              Icons.monetization_on,
              isActive: ModalRoute.of(context)?.settings.name == '/coins',
            ),
            _buildMenuItem(
              context,
              AppLocalizations.of(context).settings,
              Icons.settings,
              isActive: ModalRoute.of(context)?.settings.name == '/settings',
              onTap: _navigateToSettings,
            ),
            const Divider(),
            // Thème
            Consumer<ThemeViewModel>(
              builder: (context, viewModel, child) => ListTile(
                leading: Icon(
                  AppTheme.isLight ? Icons.dark_mode : Icons.light_mode,
                  color: AppTheme.textMutedColor,
                ),
                title: Text(AppTheme.isLight ? AppLocalizations.of(context).darkMode : AppLocalizations.of(context).lightMode),
                onTap: () {
                  viewModel.setTheme(
                    viewModel.themeMode == ThemeMode.dark
                        ? ThemeMode.light
                        : ThemeMode.dark,
                  );
                  _closeDrawerIfOpen();
                },
              ),
            ),
            const Divider(),
            // Déconnexion
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: Text(
                AppLocalizations.of(context).logout,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                ModernDialog.show(
                  context: context,
                  title: AppLocalizations.of(context).logout,
                  message: AppLocalizations.of(context).translate('confirm_logout'),
                  type: DialogType.warning,
                  confirmText: AppLocalizations.of(context).logout,
                  cancelText: AppLocalizations.of(context).cancel,
                  onConfirm: () {
                    context
                        .read<AuthBloc>()
                        .add(const AuthLogoutRequested());
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon, {
    bool isActive = false,
    String? badge,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppColors.primaryColor : AppColors.textMutedColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? AppColors.primaryColor : null,
          fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildUserHeader() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  height: 16,
                  child: LinearProgressIndicator(),
                ),
                SizedBox(height: 4),
                SizedBox(
                  width: 80,
                  height: 12,
                  child: LinearProgressIndicator(),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final user = _currentUser;
    final hasImage = user?.imageUrl != null && user!.imageUrl!.isNotEmpty;
    final initials = _getInitials(user?.fullName ?? 'U');

    return InkWell(
      onTap: _navigateToProfile,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primaryColor,
              backgroundImage: hasImage ? NetworkImage(user.imageUrl!) : null,
              child: hasImage
                  ? null
                  : Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.fullName ?? 'Utilisateur',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user?.userName != null && user!.userName.isNotEmpty)
                    Text(
                      '@${user.userName}',
                      style: TextStyle(
                        color: AppTheme.textMutedColor,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (user?.professionalTitle != null &&
                      user!.professionalTitle!.isNotEmpty)
                    Text(
                      user.professionalTitle!,
                      style: TextStyle(
                        color: AppTheme.textMutedColor,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMutedColor,
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}

class _DrawerMenuItemConfig {
  final String title;
  final IconData icon;
  final String routeName;
  final String? badge;
  final VoidCallback? onTap;

  const _DrawerMenuItemConfig({
    required this.title,
    required this.icon,
    required this.routeName,
    this.badge,
    this.onTap,
  });
}

class _DrawerNotificationItem {
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  const _DrawerNotificationItem({
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  factory _DrawerNotificationItem.fromPayload(Map<String, dynamic> payload) {
    final title = _safeString(
      payload['title'] ?? payload['type'],
      fallback: 'Notification',
    );
    final message = _safeString(
      payload['message'] ?? payload['content'] ?? payload['text'],
      fallback: 'Nouvelle notification',
    );
    final rawDate = payload['createdAt'] ?? payload['date'] ?? payload['timestamp'];
    DateTime? parsed;
    if (rawDate != null) {
      try {
        parsed = DateTime.tryParse(rawDate.toString());
      } catch (_) {
        parsed = null;
      }
    }

    return _DrawerNotificationItem(
      title: title,
      message: message,
      createdAt: parsed ?? DateTime.now(),
      isRead: false,
    );
  }

  static String _safeString(
    Object? value, {
    required String fallback,
  }) {
    if (value == null) return fallback;
    try {
      final text = value.toString();
      if (text.isEmpty || text == 'undefined' || text == 'null') {
        return fallback;
      }
      return text;
    } catch (_) {
      return fallback;
    }
  }
  _DrawerNotificationItem copyWith({
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return _DrawerNotificationItem(
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

class _NotificationsView extends StatelessWidget {
  final List<_DrawerNotificationItem> notifications;

  const _NotificationsView({required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none,
                      size: 52, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  const Text('Aucune notification pour le moment'),
                ],
              ),
            )
          : ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = notifications[index];
                final created =
                    '${item.createdAt.day.toString().padLeft(2, '0')}/${item.createdAt.month.toString().padLeft(2, '0')} ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}';

                return ListTile(
                  leading: Icon(
                    item.isRead ? Icons.notifications_none : Icons.notifications_active,
                    color: item.isRead ? Colors.grey : AppColors.primaryColor,
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  subtitle: Text('${item.message}\n$created'),
                  isThreeLine: true,
                );
              },
            ),
    );
  }
}
