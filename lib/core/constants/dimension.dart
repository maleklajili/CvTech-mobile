// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../../app.dart';

class Dimensions {
  Dimensions._();

  // Height constants
  static const double heightTiny = 4.0;

  // Width constants
  static const double widthTiny = 4.0;

  // Spacing constants - Horizontal
  static const double heightTinyHorizontal = 4.0;
  static const double heightSmallHorizontal = 8.0;
  static const double heightMediumHorizontal = 16.0;
  static const double heightLargeHorizontal = 24.0;
  static const double heightXLargeHorizontal = 32.0;
  static const double heightHugeHorizontal = 48.0;
  static const double heightGiantHorizontal = 64.0;

  // Spacing constants - Vertical
  static const double heightTinyVertical = 4.0;
  static const double heightSmallVertical = 8.0;
  static const double heightMediumVertical = 16.0;
  static const double heightLargeVertical = 24.0;
  static const double heightXLargeVertical = 32.0;
  static const double heightHugeVertical = 48.0;
  static const double heightGiantVertical = 64.0;

  // Padding constants
  static const double paddingTiny = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  static const double paddingHuge = 48.0;

  // Padding constants - Horizontal
  static const double paddingTinyHorizontal = 4.0;
  static const double paddingSmallHorizontal = 8.0;
  static const double paddingMediumHorizontal = 16.0;
  static const double paddingLargeHorizontal = 24.0;
  static const double paddingXLargeHorizontal = 32.0;
  static const double paddingHugeHorizontal = 48.0;

  // Padding constants - Vertical
  static const double paddingTinyVertical = 4.0;
  static const double paddingSmallVertical = 8.0;
  static const double paddingMediumVertical = 16.0;
  static const double paddingLargeVertical = 24.0;
  static const double paddingXLargeVertical = 32.0;
  static const double paddingHugeVertical = 48.0;

  // Border radius constants
  static const double tinyRadius = 4.0;
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 16.0;
  static const double xl = 24.0;

  static const double xxxl = 32.0;

  static const smallRadius = Radius.circular(s);
  static const mediumRadius = Radius.circular(m);
  static const largeRadius = Radius.circular(l);
  static const extraLargeRadius = Radius.circular(xl);
  static const hugeRadius = Radius.circular(xxxl);

  static const BorderRadius smallBorderRadius = BorderRadius.all(
    smallRadius,
  );
  static const BorderRadius mediumBorderRadius = BorderRadius.all(
    mediumRadius,
  );
  static const BorderRadius largeBorderRadius = BorderRadius.all(
    largeRadius,
  );
  static const BorderRadius extraLargeBorderRadius = BorderRadius.all(
    extraLargeRadius,
  );

  static const BorderRadius hugeBorderRadius = BorderRadius.all(
    hugeRadius,
  );

  // Icon sizes
  static const double smallIcon = 16.0;
  static const double mediumIcon = 24.0;
  static const double largeIcon = 32.0;
  static const double xLargeIcon = 48.0;

  // Button heights
  static const double smallButtonHeight = 32.0;
  static const double mediumButtonHeight = 44.0;
  static const double largeButtonHeight = 56.0;

  // Convenience methods for EdgeInsets
  static EdgeInsets get paddingAllTiny => const EdgeInsets.all(paddingTiny);
  static EdgeInsets get paddingAllSmall => const EdgeInsets.all(paddingSmall);
  static EdgeInsets get paddingAllMedium => const EdgeInsets.all(paddingMedium);
  static EdgeInsets get paddingAllLarge => const EdgeInsets.all(paddingLarge);

  // Horizontal padding (left and right)
  static EdgeInsets get horizontalPaddingSmall =>
      const EdgeInsets.symmetric(horizontal: paddingSmallHorizontal);
  static EdgeInsets get horizontalPaddingMedium =>
      const EdgeInsets.symmetric(horizontal: paddingMediumHorizontal);
  static EdgeInsets get horizontalPaddingLarge =>
      const EdgeInsets.symmetric(horizontal: paddingLargeHorizontal);

  // Vertical padding (top and bottom)
  static EdgeInsets get verticalPaddingSmall =>
      const EdgeInsets.symmetric(vertical: paddingSmallVertical);
  static EdgeInsets get verticalPaddingMedium =>
      const EdgeInsets.symmetric(vertical: paddingMediumVertical);
  static EdgeInsets get verticalPaddingLarge =>
      const EdgeInsets.symmetric(vertical: paddingLargeVertical);

  static final dpr = MediaQuery.of(mainContext).devicePixelRatio;

  /// SizedBox with height of 5
  static const heightSmall = SizedBox(height: s);

  /// SizedBox with height of 10
  static const heightMedium = SizedBox(height: m);

  /// SizedBox with height of 15
  static const heightLarge = SizedBox(height: l);

  /// SizedBox with height of 20
  static const heightExtraLarge = SizedBox(height: xl);

  /// SizedBox with height of 35
  static const heightHuge = SizedBox(height: xxxl);

  // ------------------------------- Width ---------------------------------- //

  /// SizedBox with width of 5
  static const widthSmall = SizedBox(width: s);

  /// SizedBox with width of 10
  static const widthMedium = SizedBox(width: m);

  /// SizedBox with width of 15
  static const widthLarge = SizedBox(width: l);

  /// SizedBox with width of 20
  static const widthExtraLarge = SizedBox(width: xl);

  /// SizedBox with width of 35
  static const widthHuge = SizedBox(width: xxxl);
}
