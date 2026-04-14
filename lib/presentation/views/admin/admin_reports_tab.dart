import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/theme/app_theme.dart';
import 'package:cv_tech/presentation/views_models/admin/admin_view_model.dart';
import 'package:cv_tech/data/models/admin/report_model.dart';
import 'package:intl/intl.dart';

class AdminReportsTab extends StatelessWidget {
  const AdminReportsTab({super.key});

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
              onPressed: () => vm.loadReports(),
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
      onRefresh: () => vm.loadReports(status: vm.reportFilter),
      child: Column(
        children: [
          // Stats bar
          _ReportStatsBar(stats: vm.reportStats),
          // Filter chips
          _FilterChips(vm: vm),
          // Reports list
          Expanded(
            child: vm.reports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(
                          'Aucun signalement',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: vm.reports.length,
                    itemBuilder: (context, index) =>
                        _ReportCard(report: vm.reports[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReportStatsBar extends StatelessWidget {
  final ReportStats stats;

  const _ReportStatsBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatBadge('En attente', stats.pending, const Color(0xFFDC6803)),
          _StatBadge('En cours', stats.reviewing, AppColors.primaryColor),
          _StatBadge('Résolu', stats.resolved, const Color(0xFF057642)),
          _StatBadge('Rejeté', stats.dismissed, Colors.grey),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatBadge(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  final AdminViewModel vm;

  const _FilterChips({required this.vm});

  @override
  Widget build(BuildContext context) {
    const filters = [
      (null, 'Tous'),
      ('pending', 'En attente'),
      ('reviewing', 'En cours'),
      ('resolved', 'Résolu'),
      ('dismissed', 'Rejeté'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((f) {
          final isActive = vm.reportFilter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f.$2),
              selected: isActive,
              onSelected: (_) => vm.loadReports(status: f.$1),
              selectedColor: AppColors.primaryColor.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isActive ? AppColors.primaryColor : null,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel report;

  const _ReportCard({required this.report});

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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(report.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    report.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(report.status),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    report.itemTypeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd/MM HH:mm').format(report.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Reason
            Row(
              children: [
                const Icon(Icons.flag, size: 16, color: Color(0xFFDC6803)),
                const SizedBox(width: 6),
                Text(
                  report.reasonLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (report.description != null && report.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                report.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            if (report.reportedByName != null) ...[
              const SizedBox(height: 6),
              Text(
                'Signalé par: ${report.reportedByName}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
            // Post author info (who published the reported post)
            if (report.reportedItemType == 'post' && report.postAuthorName != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (report.postAuthorImage != null)
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: NetworkImage(report.postAuthorImage!),
                            onBackgroundImageError: report.postAuthorImage != null ? (_, __) {} : null,
                          )
                        else
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.red.shade100,
                            child: Text(
                              report.postAuthorName!.isNotEmpty
                                  ? report.postAuthorName![0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Publié par: ${report.postAuthorName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              if (report.postFlagged == true)
                                Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        size: 12, color: Colors.orange.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Toxicité: ${((report.postToxicityScore ?? 0) * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (report.postTitle != null && report.postTitle!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        report.postTitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (report.postContent != null && report.postContent!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        report.postContent!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            // Actions
            if (report.status == 'pending' || report.status == 'reviewing') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (report.status == 'pending')
                    _ActionButton(
                      label: 'Examiner',
                      color: const Color(0xFF0A66C2),
                      onTap: () => vm.updateReportStatus(report.id,
                          status: 'reviewing'),
                    ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    label: 'Résoudre',
                    color: const Color(0xFF057642),
                    onTap: () => _showResolveDialog(context, vm, report.id),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    label: 'Rejeter',
                    color: Colors.grey,
                    onTap: () => vm.updateReportStatus(report.id,
                        status: 'dismissed'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showResolveDialog(
      BuildContext context, AdminViewModel vm, String reportId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Résoudre le signalement'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Notes de résolution (optionnel)',
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
              vm.updateReportStatus(reportId,
                  status: 'resolved',
                  notes: controller.text.trim().isNotEmpty
                      ? controller.text.trim()
                      : null);
              Navigator.pop(ctx);
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFDC6803);
      case 'reviewing':
        return const Color(0xFF0A66C2);
      case 'resolved':
        return const Color(0xFF057642);
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ),
    );
  }
}
