// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';

enum ToastType {
  success,
  error,
  warning,
  info,
}

class CustomToast {
  static void show({
    required BuildContext context,
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    String? title,
  }) {
    // Supprimer les anciens toasts
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final config = _getToastConfig(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: config.iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                config.icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: title != null ? 12 : 14,
                      color: Colors.white.withOpacity(title != null ? 0.9 : 1),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: config.bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  /// Toast de succès
  static void success(BuildContext context, String message, {String? title}) {
    show(
      context: context,
      message: message,
      type: ToastType.success,
      title: title ?? 'Succès',
    );
  }

  /// Toast d'erreur
  static void error(BuildContext context, String message, {String? title}) {
    show(
      context: context,
      message: message,
      type: ToastType.error,
      title: title ?? 'Erreur',
      duration: const Duration(seconds: 4),
    );
  }

  /// Toast d'avertissement
  static void warning(BuildContext context, String message, {String? title}) {
    show(
      context: context,
      message: message,
      type: ToastType.warning,
      title: title ?? 'Attention',
    );
  }

  /// Toast d'information
  static void info(BuildContext context, String message, {String? title}) {
    show(
      context: context,
      message: message,
      type: ToastType.info,
      title: title,
    );
  }

  static _ToastConfig _getToastConfig(ToastType type) {
    switch (type) {
      case ToastType.success:
        return _ToastConfig(
          bgColor: const Color(0xFF2E7D32),
          iconBgColor: const Color(0xFF4CAF50),
          icon: Icons.check_circle_outline,
        );
      case ToastType.error:
        return _ToastConfig(
          bgColor: AppColors.errorColor,
          iconBgColor: const Color(0xFFEF5350),
          icon: Icons.error_outline,
        );
      case ToastType.warning:
        return _ToastConfig(
          bgColor: const Color(0xFFF57C00),
          iconBgColor: const Color(0xFFFF9800),
          icon: Icons.warning_amber_outlined,
        );
      case ToastType.info:
        return _ToastConfig(
          bgColor: AppColors.primaryColor,
          iconBgColor: AppColors.primaryColor.withOpacity(0.8),
          icon: Icons.info_outline,
        );
    }
  }
}

class _ToastConfig {
  final Color bgColor;
  final Color iconBgColor;
  final IconData icon;

  _ToastConfig({
    required this.bgColor,
    required this.iconBgColor,
    required this.icon,
  });
}
