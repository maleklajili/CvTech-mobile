// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/core/constants/dimension.dart';
import 'package:cv_tech/presentation/views/profile/widgets/tab_profile/info_tab/generate_cv/generate_cv.dart';
import 'package:cv_tech/theme/app_theme.dart';
import '../../../../../../core/constants/app_colors.dart';

class InfoTab extends StatelessWidget {
  const InfoTab({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildInfoTab();
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'À propos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Développeur web passionné avec 8 ans d\'expérience, spécialisé dans les technologies JavaScript modernes. J\'aime créer des interfaces intuitives et des architectures backend robustes. Toujours à la recherche de nouveaux défis techniques et d\'opportunités d\'apprentissage.',
                    style: TextStyle(fontSize: 14),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Voir plus',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Dimensions.heightMedium,
                  // Tags de compétences
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'React',
                      'Next.js',
                      'TypeScript',
                      'Node.js',
                      'GraphQL',
                      'UI/UX',
                      'Tailwind CSS',
                    ]
                        .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          Dimensions.heightExtraLarge,
          // Informations de contact
          Card(
            child: Padding(
              padding: Dimensions.paddingAllMedium,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations de contact',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Dimensions.heightExtraLarge,
                  _buildContactItem(
                    Icons.email,
                    'jean.dupont@example.com',
                  ),
                  Dimensions.heightLarge,
                  _buildContactItem(
                    Icons.phone,
                    '+33 6 12 34 56 78',
                  ),
                  Dimensions.heightLarge,
                  _buildContactItem(
                    Icons.location_on,
                    'Paris, France',
                  ),
                  Dimensions.heightLarge,
                  _buildContactItem(
                    Icons.language,
                    'jeandupont.dev',
                    isLink: true,
                  ),
                  const SizedBox(height: 12),
                  _buildContactItem(
                    Icons.calendar_today,
                    'Membre depuis Janvier 2022',
                  ),
                  const SizedBox(height: 12),
                  _buildContactItem(
                    Icons.translate,
                    'Français, Anglais, Espagnol',
                  ),
                ],
              ),
            ),
          ),
          Dimensions.heightExtraLarge,
          // Bouton Générer CV
          const GenerateCv()
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text, {bool isLink = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.textMutedColor,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isLink ? AppColors.primaryColor : null,
          ),
        ),
      ],
    );
  }
}
