// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/theme/custom_app_bar_theme.dart';
import 'package:cv_tech/theme/custom_bottom_navigation_theme.dart';
import 'package:cv_tech/theme/custom_divider_theme.dart';
import 'package:cv_tech/theme/custom_floating_action_buttom_theme.dart';
import 'package:cv_tech/theme/custom_icon_button_theme.dart';
import 'package:cv_tech/theme/custom_icon_theme.dart';
import 'package:cv_tech/theme/custom_text_theme.dart';
import '../app.dart';

class AppTheme {
  static bool get isLight =>
      Theme.of(mainContext).brightness == Brightness.light;

  static Color get backgroundColor =>
      isLight ? AppColors.backgroundColor : AppColors.darkBackgroundColor;

  static Color get textColor =>
      isLight ? AppColors.textColor : AppColors.darkTextColor;
  static Color get textMutedColor =>
      isLight ? AppColors.textMutedColor : AppColors.darkTextMutedColor;

  static Color get dividerColor =>
      isLight ? AppColors.dividerColor : AppColors.darkDividerColor;

  static Color get cardColor =>
      isLight ? AppColors.surfaceColor : AppColors.darkSurfaceColor;

  static Color get surfaceColor =>
      isLight ? AppColors.backgroundColor : AppColors.darkBackgroundColor;

  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
        primaryColor: AppColors.primaryColor,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primaryColor,
          secondary: AppColors.secondaryColor,
          surface: AppColors.surfaceColor,
          error: AppColors.errorColor,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.textColor,
          onError: Colors.white,
          brightness: Brightness.light,
        ),
        appBarTheme: CustomAppBarTheme.lightAppBarTheme,
        textTheme: CustomTextTheme.lighttextTheme,
        bottomNavigationBarTheme:
            CustomBottomNavigationTheme.lightBottomNavigationBarTheme,
        floatingActionButtonTheme:
            CustomFloatingActionButtomTheme.lightFloatingActionTheme,
        dividerTheme: CustomDividerTheme.lightDividerTheme,
        iconTheme: CustomIconTheme.lightIconTheme,
        iconButtonTheme: CustomIconButtonTheme.lightCustomIconButtonTheme,
      );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: false,
        primaryColor: AppColors.primaryColor,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryColor,
          secondary: AppColors.secondaryColor,
          surface: AppColors.darkSurfaceColor,
          error: AppColors.errorColor,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.darkTextColor,
          onError: Colors.white,
          brightness: Brightness.dark,
        ),
        appBarTheme: CustomAppBarTheme.darkAppBarTheme,
        textTheme: CustomTextTheme.darktextTheme,
        bottomNavigationBarTheme:
            CustomBottomNavigationTheme.darkBottomNavigationBarTheme,
        floatingActionButtonTheme:
            CustomFloatingActionButtomTheme.darkFloatingActionTheme,
        dividerTheme: CustomDividerTheme.darkDividerTheme,
        iconTheme: CustomIconTheme.darkIconTheme,
        iconButtonTheme: CustomIconButtonTheme.darkCustomIconButtonTheme,
      );
}
