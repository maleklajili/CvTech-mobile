import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/presentation/views_models/payment/payment_view_model.dart';

class PlansView extends StatelessWidget {
  const PlansView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentViewModel>(
      builder: (context, vm, _) {
        // If a plan is selected, show the transfer form
        if (vm.selectedPlan != null) {
          return _buildTransferForm(context, vm);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Choisir un plan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Actuel : ${_planLabel(vm.currentPlan)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Plan cards
            ...PaymentViewModel.plans.map(
              (plan) => _buildPlanCard(context, vm, plan),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransferForm(BuildContext context, PaymentViewModel vm) {
    final planName = vm.selectedPlanDisplayName;
    final planPrice = vm.selectedPlanPrice;
    final bank = vm.bankInfo;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Title
        Text(
          'Paiement par virement — Plan $planName',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Montant : ${planPrice.toStringAsFixed(2)} TND',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),

        // Bank info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFCCDDFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance, size: 20, color: Color(0xFF0A66C2)),
                  SizedBox(width: 8),
                  Text(
                    'Informations bancaires',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0A66C2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (bank != null) ...[
                _bankRow('Banque', bank.bankName, context),
                _bankRow('Titulaire', bank.accountHolder, context),
                _bankRow('RIB', bank.rib, context),
                _bankRow('IBAN', bank.iban, context),
                _bankRow('SWIFT', bank.swift, context),
              ] else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Instructions
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Color(0xFF92400E)),
                  SizedBox(width: 8),
                  Text(
                    'Instructions',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                '1. Effectuez le virement bancaire avec le montant indiqué\n'
                '2. Prenez une capture d\'écran ou photo du reçu\n'
                '3. Joignez la preuve ci-dessous\n'
                '4. Votre plan sera activé sous 24-48h après vérification',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF78350F),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Upload proof
        const Text(
          'Preuve de virement',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: vm.pickTransferProof,
          child: Container(
            height: vm.transferProof != null ? null : 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: vm.transferProof != null
                    ? const Color(0xFF1D9E75)
                    : Colors.grey.shade300,
                width: vm.transferProof != null ? 2 : 1,
              ),
            ),
            child: vm.transferProof != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.file(
                          vm.transferProof!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1D9E75),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          size: 36, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'Appuyez pour joindre la preuve',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Image (JPEG, PNG)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        // Error message
        if (vm.errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Text(
              vm.errorMessage!,
              style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626)),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: vm.transferProof != null ? vm.submitPayment : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A66C2),
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Envoyer la demande de paiement',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _bankRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copié'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Icon(Icons.copy, size: 16, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
      BuildContext context, PaymentViewModel vm, PlanInfo plan) {
    final isCurrent = vm.currentPlan == plan.id;
    final isPro = plan.id == 'pro';
    final isGold = plan.id == 'gold';

    Color borderColor;
    Color bgColor;
    Color accentColor;
    Color textColor;

    if (isGold) {
      borderColor = const Color(0xFFBA7517);
      bgColor = const Color(0xFFFAEEDA);
      accentColor = const Color(0xFFBA7517);
      textColor = const Color(0xFF412402);
    } else if (isPro) {
      borderColor = const Color(0xFF0A66C2);
      bgColor = const Color(0xFFE8F0F9);
      accentColor = const Color(0xFF0A66C2);
      textColor = const Color(0xFF0C447C);
    } else {
      borderColor = Colors.grey.shade300;
      bgColor = Colors.white;
      accentColor = Colors.grey;
      textColor = Colors.grey.shade600;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: (isPro || isGold) ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: isCurrent ? Colors.grey.shade200 : accentColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCurrent ? 'Actuel' : plan.badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isCurrent ? Colors.grey.shade600 : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Price
          Text(
            plan.price == 0
                ? '0 TND'
                : '${plan.price.toStringAsFixed(2)} TND',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            plan.period,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),

          // Features
          ...plan.features.map((f) => _buildFeatureRow(f, accentColor)),
          const SizedBox(height: 12),

          // Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCurrent || plan.id == 'free'
                  ? null
                  : () => vm.selectPlan(plan.id),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isCurrent ? Colors.grey.shade200 : accentColor,
                disabledBackgroundColor: Colors.grey.shade200,
                foregroundColor:
                    isCurrent ? Colors.grey.shade600 : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                isCurrent ? 'Plan actuel' : 'Passer à ${plan.name} →',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(PlanFeature feature, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: feature.included ? dotColor : const Color(0xFFE24B4A),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature.text,
              style: TextStyle(
                fontSize: 13,
                color: feature.included ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _planLabel(String plan) {
    switch (plan) {
      case 'pro':
        return 'Pro';
      case 'gold':
        return 'Gold';
      default:
        return 'Gratuit';
    }
  }
}
