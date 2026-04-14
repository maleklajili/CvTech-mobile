import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/presentation/views_models/payment/payment_view_model.dart';

class PaymentSuccessView extends StatelessWidget {
  const PaymentSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentViewModel>(
      builder: (context, vm, _) {
        final planName = vm.selectedPlanDisplayName;
        final price = vm.selectedPlanPrice;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Success icon
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEAF3DE),
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFF1D9E75),
                  size: 36,
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'Demande envoyée !',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Votre demande de paiement pour le plan $planName\na bien été reçue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Pending verification card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule,
                            color: Color(0xFF92400E), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'En attente de vérification',
                          style: TextStyle(
                            color: Color(0xFF92400E),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Notre équipe va vérifier votre virement.\nVotre plan sera activé sous 24-48h.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Recap card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Récapitulatif',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _recapRow('Plan', planName),
                    _recapRow(
                        'Montant', '${price.toStringAsFixed(2)} TND'),
                    _recapRow('Mode', 'Virement bancaire'),
                    _recapRow('Statut', 'En attente'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // What happens next
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCCDDFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Que se passe-t-il ensuite ?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0A66C2),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _nextStepRow(
                        '1', 'Notre équipe vérifie votre preuve de virement'),
                    _nextStepRow(
                        '2', 'Votre plan $planName est activé automatiquement'),
                    _nextStepRow('3',
                        'Vous recevrez une notification de confirmation'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // CTA button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    vm.resetState();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A66C2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Retour à l\'accueil',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _recapRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextStepRow(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFDCE8FA),
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0A66C2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
