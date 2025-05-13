// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/core/constants/dimension.dart';
import 'package:cv_tech/theme/app_theme.dart';

class PrincipalInformation extends StatelessWidget {
  const PrincipalInformation({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jean Dupont',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '@jeandupont',
          style: TextStyle(
            color: AppTheme.textMutedColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.description,
              size: 14,
              color: AppTheme.textMutedColor,
            ),
            Dimensions.widthSmall,
            const Text(
              'Développeur Full Stack Senior',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
