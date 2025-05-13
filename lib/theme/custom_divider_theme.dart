// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';

class CustomDividerTheme {
  static DividerThemeData createDividerThemeData({
    required Color color,
  }) {
    return DividerThemeData(
      color: color,
      thickness: 1,
    );
  }

  static final lightDividerTheme = createDividerThemeData(
    color: AppColors.dividerColor,
  );

  static final darkDividerTheme = createDividerThemeData(
    color: AppColors.darkDividerColor,
  );
}
