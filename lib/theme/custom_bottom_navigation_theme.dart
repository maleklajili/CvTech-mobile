// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../core/constants/app_colors.dart';

class CustomBottomNavigationTheme {
  static BottomNavigationBarThemeData createBottomNavigationBarTheme({
    required Color backgroundColor,
    required Color selectedItemColor,
    required Color unselectedItemColor,
  }) {
    return BottomNavigationBarThemeData(
      backgroundColor: backgroundColor,
      selectedItemColor: selectedItemColor,
      unselectedItemColor: unselectedItemColor,
    );
  }

  static final lightBottomNavigationBarTheme = createBottomNavigationBarTheme(
    backgroundColor: AppColors.backgroundColor,
    selectedItemColor: AppColors.primaryColor,
    unselectedItemColor: AppColors.textMutedColor,
  );

  static final darkBottomNavigationBarTheme = createBottomNavigationBarTheme(
    backgroundColor: AppColors.darkBackgroundColor,
    selectedItemColor: AppColors.primaryColor,
    unselectedItemColor: AppColors.darkTextMutedColor,
  );
}
