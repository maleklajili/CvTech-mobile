// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/theme/app_theme.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/dimension.dart';

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.message_outlined, size: 16),
            label: const Text('Message'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: Dimensions.extraLargeBorderRadius,
              ),
            ),
          ),
        ),
        Dimensions.widthSmall,
        Container(
          padding: Dimensions.paddingAllSmall,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: AppTheme.dividerColor,
            ),
            shape: BoxShape.circle,
          ),

          // Adjust padding as needed
          child: const Icon(
            Icons.share_outlined,
            size: 20,
          ),
        ),
        Dimensions.widthSmall,
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.person_add_outlined, size: 16),
            label: const Text('Suivre'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              shape: RoundedRectangleBorder(
                borderRadius: Dimensions.extraLargeBorderRadius,
                side: BorderSide(
                  color: AppTheme.dividerColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
