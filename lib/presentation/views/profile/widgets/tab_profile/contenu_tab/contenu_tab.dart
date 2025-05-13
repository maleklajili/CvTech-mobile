// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../../../../../../core/constants/app_colors.dart';

class ContenuTab extends StatelessWidget {
  const ContenuTab({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildContenuTab();
  }

  Widget _buildContenuTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildContenuItem(
            'Posts',
            Icons.message,
            const Color(0xFFF97316),
            const Color(0xFFEF4444),
            '1.2k posts • 42.3k karma',
            '/posts',
          ),
          const SizedBox(height: 5),
          _buildContenuItem(
            'Sauvegardés',
            Icons.bookmark,
            const Color(0xFF8B5CF6),
            const Color(0xFF7C3AED),
            '36 posts • 12 communautés',
            '/sauvegardes',
          ),
        ],
      ),
    );
  }

  Widget _buildContenuItem(
    String title,
    IconData icon,
    Color gradientStart,
    Color gradientEnd,
    String subtitle,
    String route,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [gradientStart, gradientEnd],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gradientStart.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textMutedColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMutedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
