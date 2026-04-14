import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/theme/app_theme.dart';
import 'package:cv_tech/presentation/views_models/admin/admin_view_model.dart';
import 'package:cv_tech/data/models/admin/pending_payment.dart';
import 'package:intl/intl.dart';

class AdminPaymentsTab extends StatelessWidget {
  const AdminPaymentsTab({super.key});

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
              onPressed: () => vm.loadPendingPayments(),
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

    if (vm.pendingPayments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'Aucun paiement en attente',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => vm.loadPendingPayments(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vm.pendingPayments.length,
        itemBuilder: (context, index) =>
            _PaymentCard(payment: vm.pendingPayments[index]),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PendingPayment payment;

  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AdminViewModel>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: payment.plan == 'gold'
                        ? const Color(0xFFFAEEDA)
                        : AppColors.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.workspace_premium,
                    color: payment.plan == 'gold'
                        ? const Color(0xFF915907)
                        : AppColors.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.userName ?? 'Utilisateur #${payment.userId.substring(0, 6)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Plan ${payment.planLabel} · ${payment.amountTnd}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yy').format(payment.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Transfer proof indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: payment.transferProof != null
                    ? const Color(0xFFEAF3DE)
                    : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    payment.transferProof != null
                        ? Icons.image
                        : Icons.warning_amber,
                    size: 14,
                    color: payment.transferProof != null
                        ? const Color(0xFF057642)
                        : const Color(0xFF92400E),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    payment.transferProof != null
                        ? 'Preuve jointe'
                        : 'Pas de preuve',
                    style: TextStyle(
                      fontSize: 12,
                      color: payment.transferProof != null
                          ? const Color(0xFF057642)
                          : const Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: vm.actionLoading
                        ? null
                        : () => _showRejectDialog(context, vm, payment.id),
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
                        : () => _showApproveDialog(context, vm, payment.id),
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
        ),
      ),
    );
  }

  void _showApproveDialog(
      BuildContext context, AdminViewModel vm, String paymentId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approuver le paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Le plan sera activé et les coins seront crédités.',
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
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              vm.approvePayment(paymentId,
                  note: controller.text.trim().isNotEmpty
                      ? controller.text.trim()
                      : null);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF057642),
            ),
            child:
                const Text('Approuver', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
      BuildContext context, AdminViewModel vm, String paymentId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter le paiement'),
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
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              vm.rejectPayment(paymentId,
                  note: controller.text.trim().isNotEmpty
                      ? controller.text.trim()
                      : null);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child:
                const Text('Rejeter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
