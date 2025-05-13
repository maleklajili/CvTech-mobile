// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/core/enums/cv_template.dart';
import 'package:cv_tech/presentation/views_models/profile/cv_template_selector_view_model.dart';
import 'package:cv_tech/theme/app_theme.dart';
import '../../../../../../../../core/constants/dimension.dart';

class TemplateOption extends StatelessWidget {
  final CvTemplate id;
  final String title;
  final String description;
  final Color color;
  final CvTemplateSelectorViewModel viewModel;
  const TemplateOption({
    super.key,
    required this.id,
    required this.viewModel,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _buildTemplateOption(context);
  }

  Widget _buildTemplateOption(BuildContext context) {
    final isSelected = viewModel.cvTemplateSelected == id;
    return GestureDetector(
      onTap: () {
        viewModel.selectTemplate(id);
      },
      child: Container(
        margin: Dimensions.verticalPaddingSmall,
        padding: Dimensions.paddingAllSmall,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            color.withOpacity(0.4),
            isSelected ? color : color.withOpacity(0.6),
          ]),
          borderRadius: Dimensions.mediumBorderRadius,
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Aperçu du modèle
            Container(
              width: 40,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Center(
                child: Text(
                  title.substring(0, 1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            Dimensions.widthLarge,
            // Informations sur le modèle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppTheme.textMutedColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Indicateur de sélection
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.green,
                  size: 15,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
