import 'dart:ui';
import 'package:flutter/material.dart';

enum DialogType { warning, success, error, info, confirm }

class ModernDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    DialogType type = DialogType.confirm,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool showCancel = true,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _ModernDialogContent(
          title: title,
          message: message,
          type: type,
          confirmText: confirmText,
          cancelText: cancelText,
          onConfirm: onConfirm,
          onCancel: onCancel,
          showCancel: showCancel,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 4 * animation.value,
            sigmaY: 4 * animation.value,
          ),
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Shorthand for delete/warning dialogs
  static Future<bool?> showDelete({
    required BuildContext context,
    required String itemName,
    VoidCallback? onConfirm,
  }) {
    return show(
      context: context,
      title: 'Supprimer',
      message: 'Êtes-vous sûr de vouloir supprimer $itemName ?',
      type: DialogType.warning,
      confirmText: 'Supprimer',
      cancelText: 'Annuler',
      onConfirm: onConfirm,
    );
  }

  /// Shorthand for success dialogs
  static Future<bool?> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      type: DialogType.success,
      confirmText: buttonText ?? 'OK',
      showCancel: false,
    );
  }

  /// Shorthand for error dialogs
  static Future<bool?> showError({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      type: DialogType.error,
      confirmText: buttonText ?? 'OK',
      showCancel: false,
    );
  }
}

class _ModernDialogContent extends StatelessWidget {
  final String title;
  final String message;
  final DialogType type;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool showCancel;

  const _ModernDialogContent({
    required this.title,
    required this.message,
    required this.type,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.showCancel = true,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getTypeConfig();
    
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
            BoxShadow(
              color: config.color.withOpacity(0.1),
              blurRadius: 40,
              spreadRadius: -10,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated icon container
                _buildIconContainer(config),
                const SizedBox(height: 20),
                
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Message
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                
                // Buttons
                _buildButtons(context, config),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer(_DialogTypeConfig config) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            config.color.withOpacity(0.1),
            config.color.withOpacity(0.2),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: config.color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                config.color,
                config.color.withOpacity(0.8),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            config.icon,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context, _DialogTypeConfig config) {
    return Row(
      children: [
        if (showCancel) ...[
          Expanded(
            child: _ModernButton(
              text: cancelText ?? 'Annuler',
              onPressed: () {
                Navigator.of(context).pop(false);
                onCancel?.call();
              },
              isOutlined: true,
              color: Colors.grey[600]!,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: _ModernButton(
            text: confirmText ?? 'Confirmer',
            onPressed: () {
              Navigator.of(context).pop(true);
              onConfirm?.call();
            },
            color: config.color,
          ),
        ),
      ],
    );
  }

  _DialogTypeConfig _getTypeConfig() {
    switch (type) {
      case DialogType.warning:
        return _DialogTypeConfig(
          color: const Color(0xFFFF6B6B),
          icon: Icons.warning_rounded,
        );
      case DialogType.success:
        return _DialogTypeConfig(
          color: const Color(0xFF4ECDC4),
          icon: Icons.check_circle_rounded,
        );
      case DialogType.error:
        return _DialogTypeConfig(
          color: const Color(0xFFFF4757),
          icon: Icons.error_rounded,
        );
      case DialogType.info:
        return _DialogTypeConfig(
          color: const Color(0xFF5B86E5),
          icon: Icons.info_rounded,
        );
      case DialogType.confirm:
        return _DialogTypeConfig(
          color: const Color(0xFF667EEA),
          icon: Icons.help_outline_rounded,
        );
    }
  }
}

class _DialogTypeConfig {
  final Color color;
  final IconData icon;

  const _DialogTypeConfig({
    required this.color,
    required this.icon,
  });
}

class _ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final bool isOutlined;

  const _ModernButton({
    required this.text,
    required this.onPressed,
    required this.color,
    this.isOutlined = false,
  });

  @override
  State<_ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<_ModernButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: widget.isOutlined
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.color,
                    widget.color.withOpacity(0.8),
                  ],
                ),
          color: widget.isOutlined ? Colors.transparent : null,
          borderRadius: BorderRadius.circular(14),
          border: widget.isOutlined
              ? Border.all(color: Colors.grey[300]!, width: 1.5)
              : null,
          boxShadow: widget.isOutlined
              ? null
              : [
                  BoxShadow(
                    color: widget.color.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: widget.isOutlined ? widget.color : Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
