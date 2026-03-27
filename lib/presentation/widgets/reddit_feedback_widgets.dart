import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/theme/app_theme.dart';

class RedditColors {
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF1F5F9);
  static const border = Color(0xFFE2E8F0);
  static const orange = Color(0xFFFF4500);
  static const orangeLight = Color(0xFFFF6534);
  static const blue = Color(0xFF2563EB);
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const upvote = Color(0xFFFF4500);
  static const downvote = Color(0xFF7193FF);
  static const gold = Color(0xFFFFB000);
  static const silver = Color(0xFFC0C0C0);
  static const success = Color(0xFF3FB950);
  static const warning = Color(0xFFD29922);
  static const error = Color(0xFFF85149);
}

class RedditTextStyles {
  static const fontFamily = 'IBMPlexSans';

  static const headline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textColor,
    letterSpacing: -0.3,
  );

  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textMutedColor,
    height: 1.5,
  );

  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textMutedColor,
    letterSpacing: 0.8,
  );

  static const karma = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: RedditColors.orange,
    letterSpacing: 0.3,
  );
}

enum RedditToastType { upvote, downvote, award, announcement, error, mod }

class RedditToast extends StatefulWidget {
  final String message;
  final String? subreddit;
  final RedditToastType type;
  final int? karmaPoints;
  final VoidCallback? onDismiss;

  const RedditToast({
    super.key,
    required this.message,
    this.subreddit,
    this.type = RedditToastType.upvote,
    this.karmaPoints,
    this.onDismiss,
  });

  @override
  State<RedditToast> createState() => _RedditToastState();
}

class _RedditToastState extends State<RedditToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideY;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _slideY = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6)),
    );
    _scale = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  _ToastConfig get _config {
    switch (widget.type) {
      case RedditToastType.upvote:
        return const _ToastConfig(
          icon: Icons.arrow_upward_rounded,
          accent: RedditColors.upvote,
          label: 'UPVOTED',
        );
      case RedditToastType.downvote:
        return const _ToastConfig(
          icon: Icons.arrow_downward_rounded,
          accent: RedditColors.downvote,
          label: 'DOWNVOTED',
        );
      case RedditToastType.award:
        return const _ToastConfig(
          icon: Icons.emoji_events_rounded,
          accent: RedditColors.gold,
          label: 'AWARDED',
        );
      case RedditToastType.announcement:
        return const _ToastConfig(
          icon: Icons.campaign_rounded,
          accent: RedditColors.blue,
          label: 'ANNOUNCEMENT',
        );
      case RedditToastType.error:
        return const _ToastConfig(
          icon: Icons.error_outline_rounded,
          accent: RedditColors.error,
          label: 'ERROR',
        );
      case RedditToastType.mod:
        return const _ToastConfig(
          icon: Icons.shield_rounded,
          accent: RedditColors.success,
          label: 'MOD ACTION',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _config;
    final isDark = !AppTheme.isLight;
    final surfaceColor = AppTheme.cardColor;
    final borderColor = AppTheme.dividerColor;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _slideY.value),
        child: Transform.scale(
          scale: _scale.value,
          child: Opacity(opacity: _opacity.value, child: child),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 3, color: cfg.accent),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: cfg.accent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(cfg.icon, color: cfg.accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                cfg.label,
                                style: RedditTextStyles.label.copyWith(
                                  color: cfg.accent,
                                ),
                              ),
                              if (widget.subreddit != null) ...[
                                const Text(' • ', style: RedditTextStyles.label),
                                Text(
                                  'r/${widget.subreddit}',
                                  style: RedditTextStyles.label.copyWith(
                                    color: RedditColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(widget.message, style: RedditTextStyles.body),
                        ],
                      ),
                    ),
                    if (widget.karmaPoints != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cfg.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: cfg.accent.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt, size: 12, color: cfg.accent),
                            const SizedBox(width: 2),
                            Text(
                              '${widget.karmaPoints! > 0 ? '+' : ''}${widget.karmaPoints}',
                              style: RedditTextStyles.karma.copyWith(
                                color: cfg.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.onDismiss,
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: RedditColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToastConfig {
  final IconData icon;
  final Color accent;
  final String label;

  const _ToastConfig({
    required this.icon,
    required this.accent,
    required this.label,
  });
}

class RedditToastService {
  static OverlayEntry? _current;

  static void _safeRemoveCurrent() {
    final current = _current;
    if (current != null && current.mounted) {
      current.remove();
    }
    _current = null;
  }

  static void show(
    BuildContext context, {
    required String message,
    String? subreddit,
    RedditToastType type = RedditToastType.upvote,
    int? karmaPoints,
    Duration duration = const Duration(seconds: 3),
  }) {
    _safeRemoveCurrent();

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), duration: duration),
        );
      }
      return;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: RedditToast(
            message: message,
            subreddit: subreddit,
            type: type,
            karmaPoints: karmaPoints,
            onDismiss: () {
              if (entry.mounted) {
                entry.remove();
              }
              if (_current == entry) {
                _current = null;
              }
            },
          ),
        ),
      ),
    );

    overlay.insert(entry);
    _current = entry;

    Future.delayed(duration, () {
      if (entry.mounted) {
        entry.remove();
      }
      if (_current == entry) {
        _current = null;
      }
    });
  }
}

enum RedditAlertType { post, modAction, ban, award, confirm, nsfw }

class RedditAlertDialog extends StatelessWidget {
  final String title;
  final String body;
  final RedditAlertType type;
  final String? subreddit;
  final String? username;
  final int? upvotes;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const RedditAlertDialog({
    super.key,
    required this.title,
    required this.body,
    this.type = RedditAlertType.confirm,
    this.subreddit,
    this.username,
    this.upvotes,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.onConfirm,
    this.onCancel,
  });

  _AlertConfig get _config {
    switch (type) {
      case RedditAlertType.post:
        return const _AlertConfig(
          icon: Icons.article_rounded,
          accent: RedditColors.orange,
          badge: 'POST',
        );
      case RedditAlertType.modAction:
        return const _AlertConfig(
          icon: Icons.shield_rounded,
          accent: RedditColors.success,
          badge: 'MOD',
        );
      case RedditAlertType.ban:
        return const _AlertConfig(
          icon: Icons.gavel_rounded,
          accent: RedditColors.error,
          badge: 'BAN',
        );
      case RedditAlertType.award:
        return const _AlertConfig(
          icon: Icons.emoji_events_rounded,
          accent: RedditColors.gold,
          badge: 'AWARD',
        );
      case RedditAlertType.confirm:
        return const _AlertConfig(
          icon: Icons.help_outline_rounded,
          accent: RedditColors.blue,
          badge: 'CONFIRM',
        );
      case RedditAlertType.nsfw:
        return const _AlertConfig(
          icon: Icons.warning_rounded,
          accent: RedditColors.error,
          badge: 'NSFW',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _config;
    final isDark = !AppTheme.isLight;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
              blurRadius: 24,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cfg.accent.withOpacity(0.06),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cfg.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(cfg.icon, color: cfg.accent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: cfg.accent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                cfg.badge,
                                style: RedditTextStyles.label.copyWith(
                                  color: cfg.accent,
                                ),
                              ),
                            ),
                            if (subreddit != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                'r/$subreddit',
                                style: RedditTextStyles.label.copyWith(
                                  color: RedditColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(title, style: RedditTextStyles.headline),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: RedditColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(body, style: RedditTextStyles.body.copyWith(height: 1.6)),
                  if (username != null || upvotes != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          if (username != null) ...[
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: RedditColors.orange.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 16,
                                color: RedditColors.orange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'u/$username',
                              style: RedditTextStyles.body.copyWith(
                                color: RedditColors.textPrimary,
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (upvotes != null) ...[
                            const Icon(
                              Icons.arrow_upward_rounded,
                              size: 14,
                              color: RedditColors.upvote,
                            ),
                            const SizedBox(width: 4),
                            Text('$upvotes', style: RedditTextStyles.karma),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _RedditButton(
                          label: cancelLabel,
                          onTap: () {
                            Navigator.of(context).pop();
                            onCancel?.call();
                          },
                          variant: _ButtonVariant.ghost,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RedditButton(
                          label: confirmLabel,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            Navigator.of(context).pop();
                            onConfirm?.call();
                          },
                          variant: _ButtonVariant.filled,
                          accent: cfg.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertConfig {
  final IconData icon;
  final Color accent;
  final String badge;

  const _AlertConfig({
    required this.icon,
    required this.accent,
    required this.badge,
  });
}

enum _ButtonVariant { ghost, filled }

class _RedditButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final _ButtonVariant variant;
  final Color accent;

  const _RedditButton({
    required this.label,
    required this.onTap,
    this.variant = _ButtonVariant.filled,
    this.accent = RedditColors.orange,
  });

  @override
  State<_RedditButton> createState() => _RedditButtonState();
}

class _RedditButtonState extends State<_RedditButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isFilled = widget.variant == _ButtonVariant.filled;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()..scale(_pressed ? 0.96 : 1.0),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isFilled
              ? (_pressed ? widget.accent.withOpacity(0.85) : widget.accent)
              : (_pressed ? RedditColors.surfaceAlt : RedditColors.background),
          borderRadius: BorderRadius.circular(8),
          border: isFilled ? null : Border.all(color: RedditColors.border),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.3,
            color: isFilled ? Colors.white : RedditColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

Future<void> showRedditAlert(
  BuildContext context, {
  required String title,
  required String body,
  RedditAlertType type = RedditAlertType.confirm,
  String? subreddit,
  String? username,
  int? upvotes,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
}) {
  HapticFeedback.lightImpact();
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.25),
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
    pageBuilder: (_, __, ___) => RedditAlertDialog(
      title: title,
      body: body,
      type: type,
      subreddit: subreddit,
      username: username,
      upvotes: upvotes,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: onConfirm,
      onCancel: onCancel,
    ),
  );
}

// Compatibility layer with App* naming used across feature code.
enum AppToastType { upvote, downvote, award, success, error, mod }

enum AppAlertType { post, ban, award, mod, confirm, nsfw }

class AppToastService {
  static void show(
    BuildContext context, {
    required String message,
    String? sub,
    AppToastType type = AppToastType.upvote,
    int? karma,
    Duration duration = const Duration(seconds: 3),
  }) {
    RedditToastService.show(
      context,
      message: message,
      subreddit: sub,
      type: _mapToast(type),
      karmaPoints: karma,
      duration: duration,
    );
  }

  static RedditToastType _mapToast(AppToastType type) {
    switch (type) {
      case AppToastType.upvote:
        return RedditToastType.upvote;
      case AppToastType.downvote:
        return RedditToastType.downvote;
      case AppToastType.award:
        return RedditToastType.award;
      case AppToastType.success:
        return RedditToastType.announcement;
      case AppToastType.error:
        return RedditToastType.error;
      case AppToastType.mod:
        return RedditToastType.mod;
    }
  }
}

Future<void> showAppAlert(
  BuildContext context, {
  required String title,
  required String body,
  AppAlertType type = AppAlertType.confirm,
  String? subreddit,
  String? username,
  int? upvotes,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
}) {
  return showRedditAlert(
    context,
    title: title,
    body: body,
    type: _mapAlert(type),
    subreddit: subreddit,
    username: username,
    upvotes: upvotes,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    onConfirm: onConfirm,
    onCancel: onCancel,
  );
}

RedditAlertType _mapAlert(AppAlertType type) {
  switch (type) {
    case AppAlertType.post:
      return RedditAlertType.post;
    case AppAlertType.ban:
      return RedditAlertType.ban;
    case AppAlertType.award:
      return RedditAlertType.award;
    case AppAlertType.mod:
      return RedditAlertType.modAction;
    case AppAlertType.confirm:
      return RedditAlertType.confirm;
    case AppAlertType.nsfw:
      return RedditAlertType.nsfw;
  }
}
