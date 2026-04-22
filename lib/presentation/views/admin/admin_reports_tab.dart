import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
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
                onPressed: () => vm.loadReports(),
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

    return RefreshIndicator(
      onRefresh: () => vm.loadReports(status: vm.reportFilter),
      child: Column(
        children: [
          _FilterChips(vm: vm),
          Expanded(
            child: vm.reports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 52, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        Text('Aucun signalement',
                            style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: vm.reports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _ReportCard(report: vm.reports[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Filter chips ─────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: filters.map((f) {
          final active = vm.reportFilter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => vm.loadReports(status: f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primaryColor
                      : AppColors.primaryColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        active ? Colors.white : AppColors.primaryColor,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Report card ──────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AdminViewModel>();
    final statusColor = _statusColor(report.status);

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
          // Top row: reporter + date + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    AppColors.primaryColor.withValues(alpha: 0.12),
                child: Text(
                  (report.reportedByName ?? 'U').isNotEmpty
                      ? (report.reportedByName ?? 'U')[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.reportedByName ?? 'Anonyme',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      'a signalé · ${DateFormat('dd/MM HH:mm').format(report.createdAt)}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  report.statusLabel,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Reason row
          Row(
            children: [
              const Icon(Icons.flag_outlined,
                  size: 15, color: Color(0xFFDC6803)),
              const SizedBox(width: 6),
              Text(
                report.reasonLabel,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const Spacer(),
              if (report.reportedItemType != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    report.itemTypeLabel,
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade600),
                  ),
                ),
            ],
          ),

          // Description
          if (report.description != null &&
              report.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              report.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],

          // Reported post author
          if (report.postAuthorName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.grey.shade200,
                    child: Text(
                      report.postAuthorName!.isNotEmpty
                          ? report.postAuthorName![0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.postAuthorName!,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        if (report.postContent != null &&
                            report.postContent!.isNotEmpty)
                          Text(
                            report.postContent!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                      ],
                    ),
                  ),
                  if (report.postFlagged == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${((report.postToxicityScore ?? 0) * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E)),
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Actions
          if (report.status == 'pending' || report.status == 'reviewing') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (report.status == 'pending') ...[
                  _ActionBtn(
                    label: 'Examiner',
                    color: AppColors.primaryColor,
                    onTap: () => vm.updateReportStatus(report.id,
                        status: 'reviewing'),
                  ),
                  const SizedBox(width: 6),
                ],
                _ActionBtn(
                  label: 'Résoudre',
                  color: const Color(0xFF057642),
                  onTap: () => _showResolveDialog(context, vm, report.id),
                ),
                const SizedBox(width: 6),
                _ActionBtn(
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
    );
  }

  void _showResolveDialog(
      BuildContext context, AdminViewModel vm, String reportId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Résoudre le signalement'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Notes de résolution (optionnel)',
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
              vm.updateReportStatus(reportId,
                  status: 'resolved',
                  notes: controller.text.trim().isNotEmpty
                      ? controller.text.trim()
                      : null);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF057642),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
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
        return AppColors.primaryColor;
      case 'resolved':
        return const Color(0xFF057642);
      default:
        return Colors.grey;
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      ),
    );
  }
}
