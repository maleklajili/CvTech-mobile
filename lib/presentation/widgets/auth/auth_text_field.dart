// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/core/constants/dimension.dart';

class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;
  final int maxLines;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.enabled = true,
    this.maxLines = 1,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword && _obscureText,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      enabled: widget.enabled,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      style: TextStyle(
        color: isDark ? AppColors.darkTextColor : AppColors.textColor,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                color: AppColors.primaryColor,
              )
            : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: isDark ? AppColors.darkTextMutedColor : AppColors.textMutedColor,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: isDark 
            ? AppColors.darkSurfaceColor 
            : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: Dimensions.mediumBorderRadius,
          borderSide: BorderSide(
            color: isDark ? AppColors.darkDividerColor : AppColors.dividerColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Dimensions.mediumBorderRadius,
          borderSide: BorderSide(
            color: isDark ? AppColors.darkDividerColor : AppColors.dividerColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Dimensions.mediumBorderRadius,
          borderSide: const BorderSide(
            color: AppColors.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Dimensions.mediumBorderRadius,
          borderSide: const BorderSide(
            color: AppColors.errorColor,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Dimensions.mediumBorderRadius,
          borderSide: const BorderSide(
            color: AppColors.errorColor,
            width: 2,
          ),
        ),
        labelStyle: TextStyle(
          color: isDark ? AppColors.darkTextMutedColor : AppColors.textMutedColor,
        ),
        hintStyle: TextStyle(
          color: isDark ? AppColors.darkTextMutedColor : AppColors.textMutedColor,
        ),
      ),
    );
  }
}
