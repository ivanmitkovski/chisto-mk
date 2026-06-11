import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Invisible OTP field overlaying visual digit boxes (non-zero hit target).
class AuthOtpHiddenField extends StatelessWidget {
  const AuthOtpHiddenField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.maxLength,
    required this.onChanged,
    required this.width,
    required this.height,
    this.enabled = true,
    this.semanticsLabel,
    this.onTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int maxLength;
  final ValueChanged<String> onChanged;
  final double width;
  final double height;
  final bool enabled;
  final String? semanticsLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Semantics(
        label: semanticsLabel,
        textField: true,
        enabled: enabled,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const <String>[AutofillHints.oneTimeCode],
          showCursor: false,
          enableInteractiveSelection: false,
          autocorrect: false,
          enableSuggestions: false,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.transparent,
            fontSize: 1,
            height: 1,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(maxLength),
          ],
          onChanged: onChanged,
          onTap: onTap,
        ),
      ),
    );
  }
}
