// Flutter imports:
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/core/constants/dimension.dart';
import 'package:cv_tech/theme/app_theme.dart';

class CustomTabBar extends StatelessWidget implements PreferredSizeWidget {
  final BuildContext? themeContext;
  final List<Widget> tabs;
  final TabController? controller;
  final bool isScrollable;
  final EdgeInsetsGeometry? padding;
  final Color? indicatorColor;
  final bool automaticIndicatorColorAdjustment;
  final double indicatorWeight;
  final EdgeInsetsGeometry? indicatorPadding;
  final TabBarIndicatorSize indicatorSize;
  final Color? labelColor;
  final TextStyle? labelStyle;
  final EdgeInsetsGeometry labelPadding;
  final Color? unselectedLabelColor;
  final TextStyle? unselectedLabelStyle;
  final DragStartBehavior dragStartBehavior;
  final MouseCursor? mouseCursor;
  final ValueChanged<int>? onTap;
  final ScrollPhysics? physics;
  final BorderRadius? splashBorderRadius;
  final MaterialStateProperty<Color?>? overlayColor;
  final bool? enableFeedback;
  final Color? dividerColor;
  final double? dividerHeight;

  const CustomTabBar({
    super.key,
    BuildContext? context,
    required this.tabs,
    this.controller,
    this.isScrollable = false,
    this.padding,
    this.indicatorColor,
    this.automaticIndicatorColorAdjustment = true,
    this.indicatorWeight = 2.0,
    this.indicatorPadding,
    this.indicatorSize = TabBarIndicatorSize.tab,
    this.labelColor,
    this.labelStyle,
    this.labelPadding = EdgeInsets.zero,
    this.unselectedLabelColor,
    this.unselectedLabelStyle,
    this.dragStartBehavior = DragStartBehavior.start,
    this.mouseCursor,
    this.onTap,
    this.physics,
    this.splashBorderRadius,
    this.overlayColor,
    this.enableFeedback,
    this.dividerColor,
    this.dividerHeight,
  }) : themeContext = context;

  Decoration _buildIndicator(BuildContext context) {
    return BoxDecoration(
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
  }

  @override
  Widget build(BuildContext context) {
    final resolvedContext = themeContext ?? context;

    return TabBar(
      tabs: tabs,
      controller: controller,
      isScrollable: isScrollable,
      padding: padding,
      indicator: _buildIndicator(resolvedContext),
      indicatorColor: indicatorColor ?? AppTheme.textColor,
        automaticIndicatorColorAdjustment:
          automaticIndicatorColorAdjustment,
      indicatorWeight: indicatorWeight,
      indicatorPadding: indicatorPadding ?? Dimensions.paddingAllSmall,
      indicatorSize: indicatorSize,
      labelColor: labelColor ?? AppTheme.textColor,
      labelStyle: labelStyle ??
          Theme.of(resolvedContext).textTheme.labelMedium,
      labelPadding: labelPadding,
      unselectedLabelColor: unselectedLabelColor ?? AppTheme.textMutedColor,
      unselectedLabelStyle: unselectedLabelStyle,
      dragStartBehavior: dragStartBehavior,
      mouseCursor: mouseCursor,
      onTap: onTap,
      physics: physics,
      splashBorderRadius: splashBorderRadius,
      overlayColor: overlayColor,
      enableFeedback: enableFeedback,
      dividerColor: dividerColor ?? Colors.transparent,
      dividerHeight: dividerHeight,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
