// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';

class CustomCardTheme {
  static CardTheme createCardTheme({
    required Color color,
  }) {
    return CardTheme(
      color: color,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  static final lightCardTheme = createCardTheme(
    color: AppColors.surfaceColor,
  );

  static final darkCardTheme = createCardTheme(
    color: AppColors.darkSurfaceColor,
  );
}
