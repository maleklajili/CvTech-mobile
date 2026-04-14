import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/coin_colors.dart';
import 'package:cv_tech/presentation/views_models/coin/coin_view_model.dart';

class PurchaseConfirmationDialog extends StatelessWidget {
  final ShopItem item;

  const PurchaseConfirmationDialog({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Consumer<CoinViewModel>(
      builder: (context, vm, _) {
        final canAfford = vm.canAfford(item.price);
        final balanceAfter = vm.balance - item.price;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: CoinColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      _iconEmoji(item.icon),
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                const Text(
                  'Confirmer l\'achat',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Item name
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),

                // Cost breakdown
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildRow('Coût', '${item.price} coins'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1),
                      ),
                      _buildRow('Solde actuel', '${vm.balance} coins'),
                      const SizedBox(height: 6),
                      _buildRow(
                        'Solde après achat',
                        '$balanceAfter coins',
                        valueColor: canAfford
                            ? CoinColors.greenCheck
                            : const Color(0xFFDC2626),
                        bold: true,
                      ),
                    ],
                  ),
                ),

                if (!canAfford) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFDC2626), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Solde insuffisant. Il vous manque ${item.price - vm.balance} coins.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canAfford
                            ? () async {
                                final success = await vm.purchaseItem(item);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? '${item.name} acheté avec succès !'
                                            : 'Échec de l\'achat',
                                      ),
                                      backgroundColor: success
                                          ? CoinColors.greenCheck
                                          : const Color(0xFFDC2626),
                                    ),
                                  );
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CoinColors.gold,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🪙', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              'Acheter — ${item.price}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String value,
      {Color? valueColor, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  String _iconEmoji(IconLabel icon) {
    switch (icon) {
      case IconLabel.sparkle: return '✨';
      case IconLabel.fileText: return '📝';
      case IconLabel.palette: return '🎨';
      case IconLabel.search: return '🔍';
      case IconLabel.rocket: return '🚀';
      case IconLabel.star: return '⭐';
      case IconLabel.clock: return '⏰';
      case IconLabel.zap: return '⚡';
    }
  }
}
