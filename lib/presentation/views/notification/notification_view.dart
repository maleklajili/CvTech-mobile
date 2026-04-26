import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/models/notification_model.dart';
import 'package:cv_tech/presentation/views/job/jobs_view.dart';
import 'package:cv_tech/presentation/views_models/notification/notification_view_model.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  late NotificationViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = NotificationViewModel();
    _viewModel.loadNotifications();
    _viewModel.fetchUnreadCount();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            Consumer<NotificationViewModel>(
              builder: (context, vm, _) {
                if (vm.unreadCount > 0) {
                  return TextButton(
                    onPressed: () => vm.markAllAsRead(),
                    child: const Text(
                      'Tout lire',
                      style: TextStyle(color: AppColors.primaryColor),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: Consumer<NotificationViewModel>(
          builder: (context, vm, _) {
            switch (vm.state) {
              case NotificationState.initial:
              case NotificationState.loading:
                return const Center(child: CircularProgressIndicator());

              case NotificationState.error:
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.textMutedColor),
                      const SizedBox(height: 12),
                      Text(
                        vm.errorMessage ?? 'Erreur de chargement',
                        style: const TextStyle(color: AppColors.textMutedColor),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => vm.loadNotifications(),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                );

              case NotificationState.loaded:
              case NotificationState.loadingMore:
                if (vm.notifications.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_none,
                            size: 64, color: AppColors.textMutedColor),
                        SizedBox(height: 12),
                        Text(
                          'Aucune notification',
                          style: TextStyle(
                              color: AppColors.textMutedColor, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    await vm.loadNotifications();
                    await vm.fetchUnreadCount();
                  },
                  child: ListView.builder(
                    itemCount: vm.notifications.length +
                        (vm.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= vm.notifications.length) {
                        if (vm.state != NotificationState.loadingMore) {
                          vm.loadMore();
                        }
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _NotificationTile(
                        notification: vm.notifications[index],
                        onTap: () => _onNotificationTap(vm, vm.notifications[index]),
                        onDismiss: () {
                          final id = vm.notifications[index].id;
                          if (id != null) vm.deleteNotification(id);
                        },
                      );
                    },
                  ),
                );
            }
          },
        ),
      ),
    );
  }

  void _onNotificationTap(NotificationViewModel vm, NotificationModel n) {
    if (!n.read && n.id != null) {
      vm.markAsRead(n.id!);
    }
    // Navigation pour les notifications d'offres d'emploi
    if (n.type == 'job_application' || n.type == 'job_application_status') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const JobsView()),
      );
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(notification.id ?? UniqueKey().toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.errorColor,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: notification.read
              ? null
              : (isDark
                  ? AppColors.primaryColor.withOpacity(0.08)
                  : AppColors.primaryColor.withOpacity(0.05)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.read
                            ? FontWeight.normal
                            : FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.description,
                      style: const TextStyle(
                        color: AppColors.textMutedColor,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(notification.createdAt),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.read)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final iconData = _iconForType(notification.type);
    final color = _colorForType(notification.type);
    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withOpacity(0.12),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'follow':
        return Icons.person_add;
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'post':
        return Icons.article;
      case 'message':
        return Icons.mail;
      case 'mention':
        return Icons.alternate_email;
      case 'community_post':
        return Icons.groups;
      case 'community_join':
        return Icons.group_add;
      case 'company_follow':
        return Icons.business;
      case 'job_application':
        return Icons.work;
      case 'job_application_status':
        return Icons.assignment_turned_in;
      case 'share':
        return Icons.share;
      case 'company_verification':
      case 'verification_request':
      case 'verification_request_update':
        return Icons.verified;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'follow':
        return Colors.blue;
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.green;
      case 'post':
        return AppColors.primaryColor;
      case 'message':
        return Colors.indigo;
      case 'mention':
        return Colors.purple;
      case 'community_post':
      case 'community_join':
        return Colors.teal;
      case 'company_follow':
        return Colors.amber.shade700;
      case 'job_application':
        return Colors.deepOrange;
      case 'job_application_status':
        return _statusColor(notification.metadata?['newStatus']?.toString());
      case 'share':
        return Colors.cyan;
      case 'company_verification':
      case 'verification_request':
      case 'verification_request_update':
        return Colors.lightBlue;
      default:
        return AppColors.textMutedColor;
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'accepted':
      case 'shortlisted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'viewed':
        return Colors.blue;
      case 'withdrawn':
        return Colors.grey;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
