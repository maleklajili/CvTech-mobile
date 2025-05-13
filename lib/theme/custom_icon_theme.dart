// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../core/constants/app_colors.dart';

class CustomIconTheme {
  static IconThemeData createIconTheme({
    required Color color,
  }) {
    return IconThemeData(
      color: color,
    );
  }

  static final lightIconTheme = createIconTheme(
    color: AppColors.textMutedColor,
  );

  static final darkIconTheme = createIconTheme(
    color: AppColors.darkTextMutedColor,
  );
}
