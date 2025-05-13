// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../../../../../theme/app_theme.dart';

class StatistquesWidget extends StatelessWidget {
  const StatistquesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('1.2k', 'Posts'),
          _buildStatItem('8.5k', 'Comm.'),
          _buildStatItem('42.3k', 'Karma'),
          _buildStatItem('256', 'Abonnés'),
          _buildStatItem('128', 'Abonne.'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textMutedColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
