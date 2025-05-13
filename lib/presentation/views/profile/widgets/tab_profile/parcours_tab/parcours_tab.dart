// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/theme/app_theme.dart';

class ParcoursTab extends StatelessWidget {
  const ParcoursTab({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildParcoursTab();
  }

  Widget _buildParcoursTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildParcoursItem(
            'Expérience',
            Icons.business,
            const Color(0xFFF97316),
            const Color(0xFFEC4899),
            '2 expériences • 5 ans',
            '/experience',
          ),
          const SizedBox(
            height: 5,
          ),
          _buildParcoursItem(
            'Formation',
            Icons.school,
            const Color(0xFF3B82F6),
            const Color(0xFF6366F1),
            '2 diplômes • 5 ans',
            '/formation',
          ),
          const SizedBox(
            height: 5,
          ),
          _buildParcoursItem(
            'Compétences',
            Icons.code,
            const Color(0xFF10B981),
            const Color(0xFF059669),
            '15 compétences • 3 domaines',
            '/competences',
          ),
          const SizedBox(
            height: 5,
          ),
          _buildParcoursItem(
            'Projets',
            Icons.folder,
            const Color(0xFFF59E0B),
            const Color(0xFFEAB308),
            '4 projets • 2 en cours',
            '/projets',
          ),
        ],
      ),
    );
  }

  Widget _buildParcoursItem(
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
                      style: TextStyle(
                        color: AppTheme.textMutedColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.textMutedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
