import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/theme/app_theme.dart';
import 'package:cv_tech/presentation/views_models/admin/admin_view_model.dart';
import 'package:cv_tech/data/models/admin/moderation_models.dart';
import 'package:intl/intl.dart';

class AdminModerationTab extends StatelessWidget {
  const AdminModerationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();

    if (vm.isLoading && vm.state != AdminState.loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.state == AdminState.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(vm.errorMessage ?? 'Erreur de chargement'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => vm.loadModeration(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => vm.loadModeration(),
      child: Column(
        children: [
          // Stats bar
          _ModerationStatsBar(stats: vm.moderationStats),
          // Toggle posts/users
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ToggleButton(
                    label: 'Posts toxiques (${vm.flaggedPosts.length})',
                    active: vm.moderationView == 0,
                    onTap: () => vm.setModerationView(0),
                  ),
                  const SizedBox(width: 8),
                  _ToggleButton(
                    label: 'Suspects (${vm.flaggedUsers.length})',
                    active: vm.moderationView == 1,
                    onTap: () => vm.setModerationView(1),
                  ),
                  const SizedBox(width: 8),
                  _ToggleButton(
                    label: 'Désactivés (${vm.bannedUsers.length})',
                    active: vm.moderationView == 2,
                    onTap: () => vm.setModerationView(2),
                  ),
                ],
              ),
            ),
          ),
          // Content
          Expanded(
            child: vm.moderationView == 0
                ? _PostsList(posts: vm.flaggedPosts)
                : vm.moderationView == 1
                    ? _UsersList(users: vm.flaggedUsers)
                    : _BannedUsersList(users: vm.bannedUsers),
          ),
        ],
      ),
    );
  }
}

class _ModerationStatsBar extends StatelessWidget {
  final ModerationStats stats;

  const _ModerationStatsBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppTheme.cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            'Posts flaggés',
            stats.flaggedPosts.toString(),
            const Color(0xFFDC6803),
          ),
          _StatItem(
            'Utilisateurs flaggés',
            stats.flaggedUsers.toString(),
            const Color(0xFFDC2626),
          ),
          _StatItem(
            'Taux toxicité',
            '${stats.toxicityRate}%',
            const Color(0xFF7C3AED),
          ),
          _StatItem(
            'Taux faux comptes',
            '${stats.fakeUserRate}%',
            AppColors.primaryColor,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primaryColor.withValues(alpha: 0.1)
              : AppTheme.dividerColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? AppColors.primaryColor : AppTheme.dividerColor,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            color: active ? AppColors.primaryColor : AppTheme.textMutedColor,
          ),
        ),
      ),
    );
  }
}

// ── Flagged Posts List ───────────────────────────────────────────────────

class _PostsList extends StatelessWidget {
  final List<FlaggedPost> posts;

  const _PostsList({required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('Aucun post toxique détecté',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: posts.length,
      itemBuilder: (context, i) => _FlaggedPostCard(post: posts[i]),
    );
  }
}

class _FlaggedPostCard extends StatelessWidget {
  final FlaggedPost post;

  const _FlaggedPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AdminViewModel>();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.warning_amber, size: 18, color: Color(0xFFDC6803)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    post.userName ?? 'Utilisateur inconnu',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  DateFormat('dd/MM HH:mm').format(post.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Content
            if (post.content != null && post.content!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Text(
                  post.content!,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            const SizedBox(height: 8),

            // Categories
            if (post.toxicityCategories.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: post.toxicityCategories.map((cat) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      cat,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF92400E)),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 10),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: vm.actionLoading
                        ? null
                        : () => vm.rejectPost(post.id),
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('Rejeter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: vm.actionLoading
                        ? null
                        : () => vm.approvePost(post.id),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approuver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF057642),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Flagged Users List ──────────────────────────────────────────────────

class _UsersList extends StatelessWidget {
  final List<FlaggedUser> users;

  const _UsersList({required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('Aucun utilisateur suspect',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: users.length,
      itemBuilder: (context, i) => _FlaggedUserCard(user: users[i]),
    );
  }
}

class _FlaggedUserCard extends StatelessWidget {
  final FlaggedUser user;

  const _FlaggedUserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AdminViewModel>();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                // Fake score badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _scoreColor(user.fakeScore).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(user.fakeScore * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _scoreColor(user.fakeScore),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Status chips
            Row(
              children: [
                if (user.isBanned)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.block, size: 12, color: Color(0xFFDC2626)),
                        SizedBox(width: 4),
                        Text('Banni',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFFDC2626))),
                      ],
                    ),
                  ),
                if (user.isFlagged && !user.isBanned)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag, size: 12, color: Color(0xFF92400E)),
                        SizedBox(width: 4),
                        Text('Suspect',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF92400E))),
                      ],
                    ),
                  ),
                if (user.banReason != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      user.banReason!,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // Actions
            Row(
              children: [
                if (user.isBanned)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: vm.actionLoading
                          ? null
                          : () => vm.unbanUser(user.id),
                      icon: const Icon(Icons.lock_open, size: 16),
                      label: const Text('Débannir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF057642),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: vm.actionLoading
                          ? null
                          : () => _showBanDialog(context, vm, user.id),
                      icon: const Icon(Icons.block, size: 16),
                      label: const Text('Bannir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBanDialog(
      BuildContext context, AdminViewModel vm, String userId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bannir l\'utilisateur'),
        content: TextField(
          controller: controller,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Raison du bannissement',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              vm.banUser(userId,
                  reason: controller.text.trim().isNotEmpty
                      ? controller.text.trim()
                      : null);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Bannir',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 0.7) return const Color(0xFFDC2626);
    if (score >= 0.4) return const Color(0xFFDC6803);
    return const Color(0xFF057642);
  }
}

// ── Banned/Deactivated Users List ───────────────────────────────────────

class _BannedUsersList extends StatelessWidget {
  final List<FlaggedUser> users;

  const _BannedUsersList({required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('Aucun utilisateur désactivé',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: users.length,
      itemBuilder: (context, i) => _BannedUserCard(user: users[i]),
    );
  }
}

class _BannedUserCard extends StatelessWidget {
  final FlaggedUser user;

  const _BannedUserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AdminViewModel>();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFFEE2E2),
                  child: Icon(Icons.person_off,
                      color: const Color(0xFFDC2626), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.block, size: 12, color: Color(0xFFDC2626)),
                      SizedBox(width: 4),
                      Text('Désactivé',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFFDC2626))),
                    ],
                  ),
                ),
              ],
            ),
            if (user.bannedAt != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'Banni le ${DateFormat('dd/MM/yyyy à HH:mm').format(user.bannedAt!)}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                  if (user.toxicPostCount > 0) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${user.toxicPostCount} post(s) toxique(s)',
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFFDC2626)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (user.banReason != null && user.banReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: Color(0xFFDC2626)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        user.banReason!,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF991B1B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: vm.actionLoading
                    ? null
                    : () => _showReactivateDialog(context, vm, user),
                icon: const Icon(Icons.lock_open, size: 16),
                label: const Text('Réactiver le compte'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF057642),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReactivateDialog(
      BuildContext context, AdminViewModel vm, FlaggedUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réactiver le compte'),
        content: Text(
          'Voulez-vous réactiver le compte de ${user.fullName} ?\n'
          'L\'utilisateur pourra à nouveau se connecter et publier.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              vm.unbanUser(user.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF057642)),
            child: const Text('Réactiver',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
