// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../core/constants/app_colors.dart';

class CustomAppBarTheme {
  static AppBarTheme createAppBarTheme({
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0,
      iconTheme: IconThemeData(color: foregroundColor),
      titleTextStyle: TextStyle(
        color: foregroundColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static final lightAppBarTheme = createAppBarTheme(
    backgroundColor: AppColors.backgroundColor,
    foregroundColor: AppColors.textColor,
  );

  static final darkAppBarTheme = createAppBarTheme(
    backgroundColor: AppColors.darkBackgroundColor,
    foregroundColor: AppColors.darkTextColor,
  );
}
