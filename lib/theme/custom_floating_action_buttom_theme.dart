// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';

class CustomFloatingActionButtomTheme {
  static FloatingActionButtonThemeData createFloatingActionButtonTheme({
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return FloatingActionButtonThemeData(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
  }

  static final lightFloatingActionTheme = createFloatingActionButtonTheme(
    backgroundColor: AppColors.primaryColor,
    foregroundColor: Colors.white,
  );

  static final darkFloatingActionTheme = createFloatingActionButtonTheme(
    backgroundColor: AppColors.primaryColor,
    foregroundColor: Colors.white,
  );
}
