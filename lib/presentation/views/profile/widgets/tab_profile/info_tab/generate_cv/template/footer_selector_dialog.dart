// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/presentation/views_models/profile/cv_template_selector_view_model.dart';
import '../../../../../../../../core/constants/dimension.dart';

class FooterSelectorDialog extends StatelessWidget {
  final CvTemplateSelectorViewModel viewModel;
  const FooterSelectorDialog({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: Dimensions.paddingAllMedium,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Dimensions.largeRadius,
          bottomRight: Dimensions.largeRadius,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: viewModel.isGenerating == true
                ? null
                : () {
                    Navigator.pop(context);
                  },
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: viewModel.cvTemplateSelected == null ||
                    viewModel.isGenerating == true
                ? null
                : () => viewModel.generateCV(),
            style: ElevatedButton.styleFrom(
              backgroundColor: viewModel.getColor(),
              foregroundColor: Colors.white,
            ),
            child: viewModel.isGenerating == true
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (viewModel.isComplete == true)
                        const Icon(Icons.check, size: 16)
                      else
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      const SizedBox(width: 8),
                      const Text('Génération...'),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.file_download, size: 16),
                      const SizedBox(width: 8),
                      Text(viewModel.isComplete == true
                          ? 'Téléchargé'
                          : 'Générer mon CV'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
