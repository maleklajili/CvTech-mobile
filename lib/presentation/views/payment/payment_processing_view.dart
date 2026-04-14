import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/presentation/views_models/payment/payment_view_model.dart';

class PaymentProcessingView extends StatelessWidget {
  const PaymentProcessingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentViewModel>(
      builder: (context, vm, _) {
        final isFailed = vm.state == PaymentState.failed;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isFailed) ...[
                const SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation(Color(0xFF1B4F8A)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Envoi en cours...',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Votre preuve de virement est en cours d\'envoi.\nVeuillez patienter.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ],

              if (isFailed) ...[
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFEF2F2),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Color(0xFFDC2626),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Échec de l\'envoi',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFDC2626), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          vm.errorMessage ?? 'Une erreur est survenue',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: vm.resetState,
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Réessayer'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
