import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/theme/app_theme.dart';
import 'package:cv_tech/presentation/views_models/admin/admin_view_model.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminCompaniesTab extends StatelessWidget {
  const AdminCompaniesTab({super.key});

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
              onPressed: () => vm.loadCompanies(),
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

    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppTheme.cardColor,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Toutes',
                  active: vm.companyFilter == null,
                  onTap: () => vm.loadCompanies(),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'En attente',
                  active: vm.companyFilter == 'pending',
                  onTap: () =>
                      vm.loadCompanies(verificationStatus: 'pending'),
                  color: const Color(0xFFDC6803),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Vérifiées',
                  active: vm.companyFilter == 'verified',
                  onTap: () =>
                      vm.loadCompanies(verificationStatus: 'verified'),
                  color: const Color(0xFF057642),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Rejetées',
                  active: vm.companyFilter == 'rejected',
                  onTap: () =>
                      vm.loadCompanies(verificationStatus: 'rejected'),
                  color: const Color(0xFFDC2626),
                ),
              ],
            ),
          ),
        ),
        // Company list
        Expanded(
          child: vm.companies.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.business_outlined,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text('Aucune entreprise trouvée',
                          style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => vm.loadCompanies(
                      verificationStatus: vm.companyFilter),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vm.companies.length,
                    itemBuilder: (context, i) =>
                        _CompanyCard(company: vm.companies[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? c.withValues(alpha: 0.1) : AppTheme.dividerColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? c : AppTheme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            color: active ? c : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final Map<String, dynamic> company;

  const _CompanyCard({required this.company});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();
    final name = company['name'] ?? company['companyName'] ?? 'Sans nom';
    final industry = company['industry'] ?? '';
    final verificationStatus =
        company['verificationStatus'] ?? 'not_requested';
    final email = company['email'] ?? '';
    final image = company['image'] as String?;
    final docs = (company['verificationDocuments'] as List?) ?? [];
    final companyId = company['_id'] as String? ?? '';
    final verificationNotes = company['verificationNotes'] as String?;
    final adminResponse = company['adminResponse'] as String?;
    final isPending = verificationStatus == 'pending';

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
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      image != null && image.isNotEmpty
                          ? NetworkImage(image)
                          : null,
                  onBackgroundImageError:
                      (image != null && image.isNotEmpty) ? (_, __) {} : null,
                  child: image == null || image.isEmpty
                      ? Icon(Icons.business,
                          color: Colors.grey.shade400, size: 22)
                      : null,
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (industry.isNotEmpty)
                        Text(
                          industry,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
                // Verification badge
                _VerificationBadge(status: verificationStatus),
              ],
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.email_outlined,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      email,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Verification notes from company
            if (verificationNotes != null && verificationNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note_outlined,
                        size: 14, color: Colors.amber.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        verificationNotes,
                        style: TextStyle(
                            fontSize: 12, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Admin response (for already processed)
            if (adminResponse != null && adminResponse.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: verificationStatus == 'rejected'
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.admin_panel_settings,
                        size: 14,
                        color: verificationStatus == 'rejected'
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF057642)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Réponse admin: $adminResponse',
                        style: TextStyle(
                            fontSize: 12,
                            color: verificationStatus == 'rejected'
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF057642)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Documents section
            if (docs.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.folder_outlined,
                            size: 16, color: Color(0xFF0369A1)),
                        const SizedBox(width: 6),
                        Text(
                          '${docs.length} document(s) de vérification',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...docs.map<Widget>((doc) {
                      final docMap = doc is Map ? doc : <String, dynamic>{};
                      final docName =
                          docMap['name'] ?? docMap['type'] ?? 'Document';
                      final docFile = docMap['file'] ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: InkWell(
                          onTap: docFile.toString().isNotEmpty
                              ? () => _openDocument(context, docFile.toString())
                              : null,
                          child: Row(
                            children: [
                              Icon(
                                _getDocIcon(docFile.toString()),
                                size: 16,
                                color: const Color(0xFF0369A1),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  docName.toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: docFile.toString().isNotEmpty
                                        ? const Color(0xFF0369A1)
                                        : Colors.grey.shade600,
                                    decoration: docFile.toString().isNotEmpty
                                        ? TextDecoration.underline
                                        : null,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (docFile.toString().isNotEmpty)
                                const Icon(Icons.open_in_new,
                                    size: 12, color: Color(0xFF0369A1)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ] else if (isPending) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 16, color: Colors.amber.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Aucun document fourni',
                      style: TextStyle(
                          fontSize: 12, color: Colors.amber.shade800),
                    ),
                  ],
                ),
              ),
            ],

            // Approve / Reject buttons for pending companies
            if (isPending && companyId.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: vm.actionLoading
                          ? null
                          : () => _showRejectDialog(context, vm, companyId),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Rejeter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: vm.actionLoading
                          ? null
                          : () => _showApproveDialog(context, vm, companyId),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approuver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF057642),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getDocIcon(String file) {
    final lower = file.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg')) return Icons.image;
    return Icons.description;
  }

  void _openDocument(BuildContext context, String fileUrl) async {
    final uri = Uri.tryParse(fileUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir le document')),
        );
      }
    }
  }

  void _showApproveDialog(
      BuildContext context, AdminViewModel vm, String companyId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approuver l\'entreprise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'L\'entreprise sera marquée comme vérifiée.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Note (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              vm.approveCompany(companyId,
                  notes: controller.text.trim().isNotEmpty
                      ? controller.text.trim()
                      : null);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF057642)),
            child: const Text('Approuver',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
      BuildContext context, AdminViewModel vm, String companyId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter l\'entreprise'),
        content: TextField(
          controller: controller,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Raison du rejet (optionnel)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              vm.rejectCompany(companyId,
                  notes: controller.text.trim().isNotEmpty
                      ? controller.text.trim()
                      : null);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626)),
            child:
                const Text('Rejeter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  final String status;

  const _VerificationBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case 'verified':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF057642);
        label = 'Vérifiée';
        icon = Icons.verified;
        break;
      case 'pending':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        label = 'En attente';
        icon = Icons.hourglass_top;
        break;
      case 'rejected':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        label = 'Rejetée';
        icon = Icons.cancel;
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade600;
        label = 'Non demandé';
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
