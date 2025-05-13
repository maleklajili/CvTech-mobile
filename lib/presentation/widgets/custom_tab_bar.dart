// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/core/constants/dimension.dart';
import 'package:cv_tech/theme/app_theme.dart';

class CustomTabBar extends TabBar {
  final BuildContext context;
  const CustomTabBar({
    super.key,
    required this.context,
    required super.tabs,
    super.controller,
    super.isScrollable,
    super.padding,
    super.indicatorColor,
    super.automaticIndicatorColorAdjustment,
    super.indicatorWeight,
    super.indicatorPadding,
    super.indicatorSize = TabBarIndicatorSize.tab,
    super.labelColor,
    super.labelStyle,
    super.labelPadding = EdgeInsets.zero,
    super.unselectedLabelColor,
    super.unselectedLabelStyle,
    super.dragStartBehavior,
    super.mouseCursor,
    super.onTap,
    super.physics,
    super.splashBorderRadius,
    super.overlayColor,
    super.enableFeedback,
    super.dividerColor,
    super.dividerHeight,
  });

  @override
  Decoration? get indicator => BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(
          color: AppTheme.backgroundColor,
          width: 0.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(4.0),
      );

  @override
  Color? get dividerColor => Colors.transparent;

  @override
  EdgeInsetsGeometry get indicatorPadding => Dimensions.paddingAllSmall;

  @override
  Color? get unselectedLabelColor => AppTheme.textMutedColor;

  @override
  Color? get indicatorColor => AppTheme.textColor;

  @override
  Color? get labelColor => AppTheme.textColor;

  @override
  TextStyle? get labelStyle => Theme.of(context).textTheme.labelMedium;
}
