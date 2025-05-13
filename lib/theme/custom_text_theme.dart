// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:google_fonts/google_fonts.dart';

// Project imports:
import '../core/constants/app_colors.dart';

class CustomTextTheme {
  static TextTheme createTextTheme(
    Color color,
    Color bodySmallColor,
  ) {
    return TextTheme(
      headlineLarge: GoogleFonts.leagueSpartan(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      headlineMedium: GoogleFonts.leagueSpartan(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      headlineSmall: GoogleFonts.leagueSpartan(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      bodyLarge: GoogleFonts.leagueSpartan(
        fontSize: 16,
        color: color,
      ),
      bodyMedium: GoogleFonts.leagueSpartan(
        fontSize: 14,
        color: color,
      ),
      bodySmall: GoogleFonts.leagueSpartan(
        fontSize: 12,
        color: bodySmallColor,
      ),
      titleLarge: GoogleFonts.leagueSpartan(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleMedium: GoogleFonts.leagueSpartan(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleSmall: GoogleFonts.leagueSpartan(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      labelLarge: GoogleFonts.leagueSpartan(
        fontSize: 14,
        color: color,
      ),
      labelMedium: GoogleFonts.leagueSpartan(
        fontSize: 12,
        color: color,
      ),
      labelSmall: GoogleFonts.leagueSpartan(
        fontSize: 10,
        color: color,
      ),
      displayLarge: GoogleFonts.leagueSpartan(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      displayMedium: GoogleFonts.leagueSpartan(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      displaySmall: GoogleFonts.leagueSpartan(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  static final lighttextTheme = createTextTheme(
    AppColors.textColor,
    AppColors.textMutedColor,
  );
  static final darktextTheme = createTextTheme(
    AppColors.darkTextColor,
    AppColors.darkTextMutedColor,
  );
}
