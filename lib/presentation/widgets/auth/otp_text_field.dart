// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/core/constants/dimension.dart';

class OtpTextField extends StatefulWidget {
  final int length;
  final void Function(String) onCompleted;
  final void Function(String)? onChanged;
  final String? initialValue; // Valeur initiale pour le mode DEV

  const OtpTextField({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
    this.initialValue,
  });

  @override
  State<OtpTextField> createState() => _OtpTextFieldState();
}

class _OtpTextFieldState extends State<OtpTextField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());

    // Pré-remplir avec la valeur initiale si fournie
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      final chars = widget.initialValue!.split('');
      for (int i = 0; i < chars.length && i < widget.length; i++) {
        _controllers[i].text = chars[i];
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    if (value.length == 1 && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    widget.onChanged?.call(_otp);

    if (_otp.length == widget.length) {
      widget.onCompleted(_otp);
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        widget.length,
        (index) => SizedBox(
          width: 45,
          height: 55,
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) => _onKeyEvent(index, event),
            child: TextFormField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextColor : AppColors.textColor,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor:
                    isDark ? AppColors.darkSurfaceColor : Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: Dimensions.smallBorderRadius,
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkDividerColor
                        : AppColors.dividerColor,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: Dimensions.smallBorderRadius,
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkDividerColor
                        : AppColors.dividerColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: Dimensions.smallBorderRadius,
                  borderSide: const BorderSide(
                    color: AppColors.primaryColor,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) => _onChanged(index, value),
            ),
          ),
        ),
      ),
    );
  }
}
