// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:cv_tech/core/constants/dimension.dart';
import 'package:cv_tech/presentation/views/profile/widgets/tab_profile/info_tab/generate_cv/template/footer_selector_dialog.dart';
import 'package:cv_tech/presentation/views_models/profile/cv_template_selector_view_model.dart';
import 'template/contenu_selector_dialog.dart';
import 'template/heading_selector_dialog.dart';

class CVTemplateSelectorDialog extends StatelessWidget {
  const CVTemplateSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CvTemplateSelectorViewModel(context),
      child: Consumer<CvTemplateSelectorViewModel>(
        builder: (context, viewModel, child) => Dialog(
          shape: const RoundedRectangleBorder(
            borderRadius: Dimensions.largeBorderRadius,
          ),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              maxWidth: 400,
              maxHeight: 500,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête
                const HeadingSelectorDialog(),
                const Divider(height: 1),

                // Contenu
                ContenuSelectorDialog(
                  viewModel: viewModel,
                ),
                // Pied de page
                FooterSelectorDialog(
                  viewModel: viewModel,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
