// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../../../../../../../core/constants/app_colors.dart';
import 'cv_template_selector_dialog.dart';

class GenerateCv extends StatelessWidget {
  const GenerateCv({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CVTemplateSelectorDialog(),
          );
        },
        icon: const Icon(Icons.description),
        label: const Text('Générer mon CV'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
