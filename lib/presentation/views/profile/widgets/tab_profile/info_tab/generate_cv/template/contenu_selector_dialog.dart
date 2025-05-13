// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/core/enums/cv_template.dart';
import 'package:cv_tech/presentation/views_models/profile/cv_template_selector_view_model.dart';
import '../../../../../../../../core/constants/dimension.dart';
import '../../../../../../../../theme/app_theme.dart';
import 'template_option.dart';

class ContenuSelectorDialog extends StatelessWidget {
  final CvTemplateSelectorViewModel viewModel;
  const ContenuSelectorDialog({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        padding: Dimensions.paddingAllMedium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sélectionnez un modèle pour générer votre CV au format PDF',
              style: TextStyle(
                color: AppTheme.textMutedColor,
              ),
            ),
            Dimensions.heightLarge,

            // Modèle Moderne
            TemplateOption(
              id: CvTemplate.modern,
              title: 'Moderne',
              description: 'Design épuré avec mise en avant des compétences',
              color: Colors.orange.shade300,
              viewModel: viewModel,
            ),

            // Modèle Français
            TemplateOption(
              id: CvTemplate.french,
              title: 'CV Français',
              description: 'Format traditionnel adapté au marché français',
              color: Colors.blue.shade300,
              viewModel: viewModel,
            ),

            // Modèle Canadien
            TemplateOption(
              id: CvTemplate.canadian,
              title: 'CV Canadien',
              description: 'Format adapté au marché nord-américain',
              color: Colors.green.shade300,
              viewModel: viewModel,
            ),
          ],
        ),
      ),
    );
  }
}
