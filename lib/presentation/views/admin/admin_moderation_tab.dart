import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
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
      return _buildError(context, vm);
    }

    return RefreshIndicator(
      onRefresh: () => vm.loadModeration(),
      child: Column(
        children: [
          _ViewToggle(vm: vm),
          Expanded(
            child: vm.moderationView == 0
                ? _PostsList(posts: vm.flaggedPosts)
                : vm.moderationView == 1
                    ? _UsersList(users: vm.flaggedUsers)
                    : _UsersList(users: vm.bannedUsers, banned: true),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, AdminViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(vm.errorMessage ?? 'Erreur de chargement',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => vm.loadModeration(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── View toggle ─────────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  final AdminViewModel vm;
  const _ViewToggle({required this.vm});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('Posts (${vm.flaggedPosts.length})', Icons.article_outlined),
      ('Suspects (${vm.flaggedUsers.length})', Icons.person_search_outlined),
      ('Bannis (${vm.bannedUsers.length})', Icons.block_outlined),
    ];

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = vm.moderationView == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => vm.setModerationView(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: EdgeInsets.only(right: i < tabs.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primaryColor
                      : AppColors.primaryColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tabs[i].$2,
                        size: 18,
                        color: active ? Colors.white : AppColors.primaryColor),
                    const SizedBox(height: 3),
                    Text(
                      tabs[i].$1,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppColors.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState(this.message);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline,
              size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(message, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

// ── Flagged Posts ────────────────────────────────────────────────────────

class _PostsList extends StatelessWidget {
  final List<FlaggedPost> posts;
  const _PostsList({required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) return const _EmptyState('Aucun post signalé');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _PostCard(post: posts[i]),
    );
  }
}

class _PostCard extends StatelessWidget {
  final FlaggedPost post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AdminViewModel>();
    final score = post.toxicityScore ?? 0.0;
    final scoreColor = score >= 0.7
        ? const Color(0xFFDC2626)
        : score >= 0.4
            ? const Color(0xFFDC6803)
            : const Color(0xFF057642);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User row
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    AppColors.primaryColor.withValues(alpha: 0.12),
                child: Text(
                  (post.userName ?? 'U').isNotEmpty
                      ? (post.userName ?? 'U')[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  post.userName ?? 'Utilisateur inconnu',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(score * 100).toInt()}%',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: scoreColor),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('dd/MM').format(post.createdAt),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),

          if ((post.content ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                post.content ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],

          if (post.toxicityCategories.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: post.toxicityCategories
                  .map((cat) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(cat,
                            style: const TextStyle(
                                fontSize: 10, color: Color(0xFF92400E))),
                      ))
                  .toList(),
            ),
          ],

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: vm.actionLoading
                      ? null
                      : () => vm.rejectPost(post.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Rejeter',
                      style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: vm.actionLoading
                      ? null
                      : () => vm.approvePost(post.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF057642),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Approuver',
                      style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Users list (flagged + banned) ────────────────────────────────────────

class _UsersList extends StatelessWidget {
  final List<FlaggedUser> users;
  final bool banned;
  const _UsersList({required this.users, this.banned = false});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return _EmptyState(
          banned ? 'Aucun utilisateur banni' : 'Aucun utilisateur suspect');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) =>
          _UserCard(user: users[i], banned: banned),
    );
  }
}

class _UserCard extends StatelessWidget {
  final FlaggedUser user;
  final bool banned;
  const _UserCard({required this.user, required this.banned});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AdminViewModel>();
    final score = user.fakeScore ?? 0.0;
    final scoreColor = score >= 0.7
        ? const Color(0xFFDC2626)
        : score >= 0.4
            ? const Color(0xFFDC6803)
            : const Color(0xFF057642);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryColor.withValues(alpha: 0.12),
            child: Text(
              user.fullName.isNotEmpty
                  ? user.fullName[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primaryColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if ((user.displaySub ?? '').isNotEmpty)
                  Text(
                    user.displaySub ?? '',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                if (user.toxicPostCount > 0)
                  Text(
                    '${user.toxicPostCount} posts toxiques',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFFDC6803)),
                  ),
                if (user.banReason != null)
                  Text(
                    'Raison: ${user.banReason}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(score * 100).toInt()}%',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: scoreColor),
                ),
              ),
              const SizedBox(height: 8),
              if (banned)
                _ActionChip(
                  label: 'Débannir',
                  color: const Color(0xFF057642),
                  onTap: vm.actionLoading
                      ? null
                      : () => vm.unbanUser(user.id),
                )
              else
                _ActionChip(
                  label: 'Bannir',
                  color: const Color(0xFFDC2626),
                  onTap: vm.actionLoading
                      ? null
                      : () => _showBanDialog(context, vm, user.id),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBanDialog(
      BuildContext context, AdminViewModel vm, String userId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Bannir l\'utilisateur'),
        content: TextField(
          controller: controller,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Raison (optionnel)',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              vm.banUser(userId,
                  reason: controller.text.trim().isNotEmpty
                      ? controller.text.trim()
                      : null);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Bannir'),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ActionChip(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey.shade200 : color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: onTap == null ? Colors.grey : Colors.white),
        ),
      ),
    );
  }
}
