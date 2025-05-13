// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../core/constants/app_colors.dart';

class CustomIconButtonTheme {
  static IconButtonThemeData createCustomIconButtonTheme({
    required Color color,
  }) {
    return IconButtonThemeData(
      style: ButtonStyle(
        iconColor: WidgetStatePropertyAll(color),
        iconSize: const WidgetStatePropertyAll(24),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        minimumSize: const WidgetStatePropertyAll(Size.zero),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        fixedSize: const WidgetStatePropertyAll(Size(24, 24)),
      ),
    );
  }

  static final lightCustomIconButtonTheme = createCustomIconButtonTheme(
    color: AppColors.textMutedColor,
  );

  static final darkCustomIconButtonTheme = createCustomIconButtonTheme(
    color: AppColors.darkTextMutedColor,
  );
}
