import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/theme/app_theme.dart';
import 'package:cv_tech/data/models/admin/admin_stats.dart';
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
          // ── Quick Stats (compact 2×3 grid) ──
          Row(
            children: [
              _MiniStat(Icons.people_rounded, stats.totalUsers.toString(),
                  'Utilisateurs', AppColors.primaryColor),
              const SizedBox(width: 8),
              _MiniStat(Icons.article_rounded, stats.totalPosts.toString(),
                  'Posts', const Color(0xFF057642)),
              const SizedBox(width: 8),
              _MiniStat(Icons.work_rounded, stats.totalJobs.toString(),
                  'Emplois', const Color(0xFFB24020)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MiniStat(Icons.public_rounded,
                  stats.totalCommunities.toString(), 'Communautés',
                  const Color(0xFF8344AD)),
              const SizedBox(width: 8),
              _MiniStat(Icons.business_rounded,
                  stats.totalCompanies.toString(), 'Entreprises',
                  const Color(0xFF915907)),
              const SizedBox(width: 8),
              _MiniStat(Icons.receipt_long_rounded,
                  stats.totalTransactions.toString(), 'Transactions',
                  AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 20),

          // ── Activity Line Chart (7 days) ──
          _SectionCard(
            title: 'Activité (7 jours)',
            child: vm.activity.isEmpty
                ? const SizedBox(
                    height: 160,
                    child: Center(child: Text('Aucune donnée')))
                : Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 4),
                    child: SizedBox(
                      height: 200,
                      child: _ActivityLineChart(activity: vm.activity),
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          // ── Engagement Pie Chart ──
          _SectionCard(
            title: 'Engagement global',
            child: SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 30,
                        sections: [
                          PieChartSectionData(
                            value: top.reactions.totalLikes.toDouble().clamp(1, double.infinity),
                            title: '${top.reactions.totalLikes}',
                            color: AppColors.primaryColor,
                            radius: 45,
                            titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          PieChartSectionData(
                            value: top.reactions.totalComments.toDouble().clamp(1, double.infinity),
                            title: '${top.reactions.totalComments}',
                            color: const Color(0xFF057642),
                            radius: 45,
                            titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          PieChartSectionData(
                            value: top.reactions.totalShares.toDouble().clamp(1, double.infinity),
                            title: '${top.reactions.totalShares}',
                            color: const Color(0xFF8344AD),
                            radius: 45,
                            titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LegendItem(AppColors.primaryColor, 'Likes',
                          top.reactions.totalLikes),
                      const SizedBox(height: 8),
                      _LegendItem(const Color(0xFF057642), 'Commentaires',
                          top.reactions.totalComments),
                      const SizedBox(height: 8),
                      _LegendItem(const Color(0xFF8344AD), 'Partages',
                          top.reactions.totalShares),
                      const SizedBox(height: 8),
                      _LegendItem(const Color(0xFF915907), 'Vues',
                          top.reactions.totalViews),
                    ],
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Coins Bar Chart ──
          _SectionCard(
            title: 'Statistiques Coins',
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 4),
              child: SizedBox(
                height: 180,
                child: _CoinsBarChart(coins: coins),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Top Posts ──
          _SectionCard(
            title: 'Top publications',
            child: top.topPostsByLikes.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('Aucune publication')),
                  )
                : Column(
                    children: top.topPostsByLikes
                        .take(5)
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                      final i = entry.key;
                      final post = entry.value;
                      return Column(
                        children: [
                          ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: _rankColor(i),
                              child: Text('${i + 1}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                            title: Text(post.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.thumb_up,
                                    size: 14, color: AppColors.primaryColor),
                                const SizedBox(width: 4),
                                Text('${post.votes}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          if (i < top.topPostsByLikes.length - 1 && i < 4)
                            Divider(
                                height: 1, color: AppTheme.dividerColor),
                        ],
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),

          // ── Top Users ──
          _SectionCard(
            title: 'Top utilisateurs actifs',
            child: top.topActiveUsers.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('Aucun utilisateur')),
                  )
                : Column(
                    children: top.topActiveUsers
                        .take(5)
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                      final i = entry.key;
                      final user = entry.value;
                      return Column(
                        children: [
                          ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: _rankColor(i),
                              child: Text('${i + 1}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                            title: Text(user.fullName,
                                style: const TextStyle(fontSize: 13)),
                            subtitle: Text(
                                '${user.postCount} posts · ${user.followerCount} abonnés',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMutedColor)),
                          ),
                          if (i < top.topActiveUsers.length - 1 && i < 4)
                            Divider(
                                height: 1, color: AppTheme.dividerColor),
                        ],
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),

          // ── Top Users par Coins ──
          _SectionCard(
            title: 'Top utilisateurs (coins)',
            child: top.topUsersByCoins.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('Aucun utilisateur')),
                  )
                : Column(
                    children: top.topUsersByCoins
                        .take(5)
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                      final i = entry.key;
                      final user = entry.value;
                      return Column(
                        children: [
                          ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: _rankColor(i),
                              child: Text('${i + 1}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                            title: Text(user.fullName,
                                style: const TextStyle(fontSize: 13)),
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
                          if (i < top.topUsersByCoins.length - 1 && i < 4)
                            Divider(
                                height: 1, color: AppTheme.dividerColor),
                        ],
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Color _rankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700);
      case 1:
        return const Color(0xFFC0C0C0);
      case 2:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.primaryColor;
    }
  }
}

// ── Mini Stat Card (compact) ──
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniStat(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor)),
            Text(label,
                style:
                    TextStyle(fontSize: 10, color: AppTheme.textMutedColor)),
          ],
        ),
      ),
    );
  }
}

// ── Section Card wrapper ──
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(title,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textColor)),
          ),
          child,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Legend Item ──
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _LegendItem(this.color, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label ($value)',
            style: TextStyle(fontSize: 12, color: AppTheme.textMutedColor)),
      ],
    );
  }
}

// ── Activity Line Chart (7 days) ──
class _ActivityLineChart extends StatelessWidget {
  final List<ActivityDay> activity;

  const _ActivityLineChart({required this.activity});

  @override
  Widget build(BuildContext context) {
    final maxUsers = activity.map((d) => d.users).fold(0, math.max);
    final maxPosts = activity.map((d) => d.posts).fold(0, math.max);
    final maxVal = math.max(maxUsers, maxPosts).toDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calcInterval(maxVal),
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppTheme.dividerColor,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style:
                    TextStyle(fontSize: 10, color: AppTheme.textMutedColor),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= activity.length) {
                  return const SizedBox();
                }
                final d = activity[idx].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    d.length > 5 ? d.substring(5) : d,
                    style: TextStyle(
                        fontSize: 9, color: AppTheme.textMutedColor),
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          _line(activity.map((d) => d.users.toDouble()).toList(),
              AppColors.primaryColor),
          _line(activity.map((d) => d.posts.toDouble()).toList(),
              const Color(0xFF057642)),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              final label = s.barIndex == 0 ? 'Utilisateurs' : 'Posts';
              return LineTooltipItem(
                '$label: ${s.y.toInt()}',
                TextStyle(
                    color: s.bar.color ?? Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  LineChartBarData _line(List<double> values, Color color) {
    return LineChartBarData(
      spots: values
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), e.value))
          .toList(),
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 1.5,
          strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1),
      ),
    );
  }

  double _calcInterval(double maxVal) {
    if (maxVal <= 10) return 2;
    if (maxVal <= 50) return 10;
    if (maxVal <= 100) return 20;
    return (maxVal / 5).roundToDouble();
  }
}

// ── Coins Bar Chart ──
class _CoinsBarChart extends StatelessWidget {
  final CoinsStats coins;

  const _CoinsBarChart({required this.coins});

  @override
  Widget build(BuildContext context) {
    final values = [
      coins.totalEarned.toDouble(),
      coins.totalSpent.toDouble(),
      coins.totalPenalties.toDouble(),
    ];
    final maxY = values.fold(0.0, math.max) * 1.3;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY < 1 ? 10 : maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppTheme.dividerColor,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style:
                    TextStyle(fontSize: 10, color: AppTheme.textMutedColor),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const labels = ['Gagnés', 'Dépensés', 'Pénalités'];
                final idx = value.toInt();
                if (idx < 0 || idx >= labels.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(labels[idx],
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textMutedColor)),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [
            BarChartRodData(
              toY: values[0],
              color: const Color(0xFF057642),
              width: 28,
              borderRadius: BorderRadius.circular(6),
            ),
          ]),
          BarChartGroupData(x: 1, barRods: [
            BarChartRodData(
              toY: values[1],
              color: AppColors.primaryColor,
              width: 28,
              borderRadius: BorderRadius.circular(6),
            ),
          ]),
          BarChartGroupData(x: 2, barRods: [
            BarChartRodData(
              toY: values[2],
              color: const Color(0xFFDC2626),
              width: 28,
              borderRadius: BorderRadius.circular(6),
            ),
          ]),
        ],
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              const labels = ['Gagnés', 'Dépensés', 'Pénalités'];
              return BarTooltipItem(
                '${labels[group.x]}: ${rod.toY.toInt()}',
                const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
      ),
    );
  }
}
