import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Zero-size OTP autofill field behind visual digit boxes.
class AuthOtpHiddenField extends StatelessWidget {
  const AuthOtpHiddenField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.maxLength,
    required this.onChanged,
    this.enabled = true,
    this.semanticsLabel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int maxLength;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox.shrink(
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
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(maxLength),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
