import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/theme/app_theme.dart';
import 'package:cv_tech/presentation/views_models/admin/admin_view_model.dart';

class AdminDashboardTab extends StatelessWidget {
  const AdminDashboardTab({super.key});

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
            Icon(Icons.error_outline, size: 48, color: AppTheme.textMutedColor),
            const SizedBox(height: 8),
            Text(vm.errorMessage ?? 'Erreur de chargement',
                style: TextStyle(color: AppTheme.textMutedColor)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => vm.loadDashboard(),
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

    final stats = vm.stats;
    final coins = vm.coinsStats;
    final top = vm.topStats;

    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: () => vm.loadDashboard(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Section title ──
          _sectionTitle('Vue d\'ensemble'),
          const SizedBox(height: 12),

          // ── Stat cards grid ──
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _StatCard(
                label: 'Utilisateurs',
                value: stats.totalUsers.toString(),
                icon: Icons.people_rounded,
                color: AppColors.primaryColor,
              ),
              _StatCard(
                label: 'Publications',
                value: stats.totalPosts.toString(),
                icon: Icons.article_rounded,
                color: const Color(0xFF057642),
              ),
              _StatCard(
                label: 'Communautés',
                value: stats.totalCommunities.toString(),
                icon: Icons.public_rounded,
                color: const Color(0xFF8344AD),
              ),
              _StatCard(
                label: 'Offres emploi',
                value: stats.totalJobs.toString(),
                icon: Icons.work_rounded,
                color: const Color(0xFFB24020),
              ),
              _StatCard(
                label: 'Entreprises',
                value: stats.totalCompanies.toString(),
                icon: Icons.business_rounded,
                color: const Color(0xFF915907),
              ),
              _StatCard(
                label: 'Transactions',
                value: stats.totalTransactions.toString(),
                icon: Icons.receipt_long_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Reactions totales ──
          _sectionTitle('Réactions totales'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: _cardDecoration(context),
            child: Row(
              children: [
                Expanded(
                    child: _CoinStat(
                        label: 'Likes',
                        value: top.reactions.totalLikes,
                        icon: Icons.thumb_up_rounded,
                        color: AppColors.primaryColor)),
                _verticalDivider(),
                Expanded(
                    child: _CoinStat(
                        label: 'Commentaires',
                        value: top.reactions.totalComments,
                        icon: Icons.comment_rounded,
                        color: const Color(0xFF057642))),
                _verticalDivider(),
                Expanded(
                    child: _CoinStat(
                        label: 'Partages',
                        value: top.reactions.totalShares,
                        icon: Icons.share_rounded,
                        color: const Color(0xFF8344AD))),
                _verticalDivider(),
                Expanded(
                    child: _CoinStat(
                        label: 'Vues',
                        value: top.reactions.totalViews,
                        icon: Icons.visibility_rounded,
                        color: const Color(0xFF915907))),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Top Posts par Likes ──
          _sectionTitle('Top publications (likes)'),
          const SizedBox(height: 12),
          if (top.topPostsByLikes.isEmpty)
            _emptyCard('Aucune publication')
          else
            Container(
              decoration: _cardDecoration(context),
              child: Column(
                children: top.topPostsByLikes.asMap().entries.map((entry) {
                  final i = entry.key;
                  final post = entry.value;
                  return Column(
                    children: [
                      ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primaryColor,
                          child: Text('${i + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                        title: Text(
                          post.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.thumb_up, size: 14, color: AppColors.primaryColor),
                            const SizedBox(width: 4),
                            Text('${post.votes}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.textColor)),
                          ],
                        ),
                      ),
                      if (i < top.topPostsByLikes.length - 1)
                        Divider(height: 1, color: AppTheme.dividerColor),
                    ],
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 24),

          // ── Top Users actifs ──
          _sectionTitle('Top utilisateurs actifs'),
          const SizedBox(height: 12),
          if (top.topActiveUsers.isEmpty)
            _emptyCard('Aucun utilisateur')
          else
            Container(
              decoration: _cardDecoration(context),
              child: Column(
                children: top.topActiveUsers.asMap().entries.map((entry) {
                  final i = entry.key;
                  final user = entry.value;
                  return Column(
                    children: [
                      ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: _rankColor(i),
                          child: Text('${i + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                        title: Text(user.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                        subtitle: Text('@${user.userName}',
                            style: TextStyle(fontSize: 11, color: AppTheme.textMutedColor)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.article, size: 14, color: const Color(0xFF057642)),
                            const SizedBox(width: 2),
                            Text('${user.postCount}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Icon(Icons.people, size: 14, color: AppColors.primaryColor),
                            const SizedBox(width: 2),
                            Text('${user.followerCount}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      if (i < top.topActiveUsers.length - 1)
                        Divider(height: 1, color: AppTheme.dividerColor),
                    ],
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 24),

          // ── Top Users par Coins ──
          _sectionTitle('Top utilisateurs (coins)'),
          const SizedBox(height: 12),
          if (top.topUsersByCoins.isEmpty)
            _emptyCard('Aucun utilisateur')
          else
            Container(
              decoration: _cardDecoration(context),
              child: Column(
                children: top.topUsersByCoins.asMap().entries.map((entry) {
                  final i = entry.key;
                  final user = entry.value;
                  return Column(
                    children: [
                      ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: _rankColor(i),
                          child: Text('${i + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                        title: Text(user.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                        subtitle: Text('@${user.userName}',
                            style: TextStyle(fontSize: 11, color: AppTheme.textMutedColor)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on,
                                size: 16, color: AppColors.primaryColor),
                            const SizedBox(width: 4),
                            Text('${user.coins}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.textColor)),
                          ],
                        ),
                      ),
                      if (i < top.topUsersByCoins.length - 1)
                        Divider(height: 1, color: AppTheme.dividerColor),
                    ],
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 24),

          // ── Coins section ──
          _sectionTitle('Statistiques Coins'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: _cardDecoration(context),
            child: Row(
              children: [
                Expanded(
                    child: _CoinStat(
                        label: 'Gagnés',
                        value: coins.totalEarned,
                        icon: Icons.arrow_upward_rounded,
                        color: const Color(0xFF057642))),
                _verticalDivider(),
                Expanded(
                    child: _CoinStat(
                        label: 'Dépensés',
                        value: coins.totalSpent,
                        icon: Icons.arrow_downward_rounded,
                        color: const Color(0xFFB24020))),
                _verticalDivider(),
                Expanded(
                    child: _CoinStat(
                        label: 'Pénalités',
                        value: coins.totalPenalties,
                        icon: Icons.remove_circle_outline_rounded,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Activity section ──
          _sectionTitle('Activité (7 derniers jours)'),
          const SizedBox(height: 12),
          if (vm.activity.isEmpty)
            Container(
              height: 120,
              alignment: Alignment.center,
              decoration: _cardDecoration(context),
              child: Text('Aucune donnée disponible',
                  style: TextStyle(color: AppTheme.textMutedColor)),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(context),
              child: Column(
                children: [
                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _legendDot(AppColors.primaryColor, 'Utilisateurs'),
                      const SizedBox(width: 12),
                      _legendDot(const Color(0xFF057642), 'Posts'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...vm.activity.map((day) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 50,
                            child: Text(
                              day.date.length > 5
                                  ? day.date.substring(5)
                                  : day.date,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMutedColor),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                _ActivityBar(
                                  value: day.users,
                                  maxValue: _maxVal(
                                      vm.activity.map((d) => d.users)),
                                  color: AppColors.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                _ActivityBar(
                                  value: day.posts,
                                  maxValue: _maxVal(
                                      vm.activity.map((d) => d.posts)),
                                  color: const Color(0xFF057642),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 70,
                            child: Text(
                              '${day.users}u · ${day.posts}p',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMutedColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppTheme.textColor,
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext? context) {
    return BoxDecoration(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.dividerColor),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 44,
      color: AppTheme.dividerColor,
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 10, color: AppTheme.textMutedColor)),
      ],
    );
  }

  int _maxVal(Iterable<int> values) {
    if (values.isEmpty) return 1;
    return values.reduce((a, b) => a > b ? a : b).clamp(1, 999999);
  }

  Widget _emptyCard(String text) {
    return Container(
      height: 80,
      alignment: Alignment.center,
      decoration: _cardDecoration(null),
      child: Text(text, style: TextStyle(color: AppTheme.textMutedColor)),
    );
  }

  Color _rankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700); // Gold
      case 1:
        return const Color(0xFFC0C0C0); // Silver
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.primaryColor;
    }
  }
}

// ── Stat Card ──
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppTheme.textMutedColor),
          ),
        ],
      ),
    );
  }
}

// ── Coin Stat ──
class _CoinStat extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _CoinStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 11, color: AppTheme.textMutedColor)),
      ],
    );
  }
}

// ── Activity Bar ──
class _ActivityBar extends StatelessWidget {
  final int value;
  final int maxValue;
  final Color color;

  const _ActivityBar({
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue > 0 ? value / maxValue : 0.0;
    return Expanded(
      child: Container(
        height: 8,
        decoration: BoxDecoration(
          color: AppTheme.dividerColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: ratio,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}
