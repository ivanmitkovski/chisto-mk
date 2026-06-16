import 'package:design_system/src/theme/app_input_outline.dart';
import 'package:design_system/src/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Standard outline field for forms outside the auth shell.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.sentences,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final InputDecoration base = appOutlineInputDecoration();
    final Widget field = TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      textCapitalization: textCapitalization,
      style: AppTypography.textTheme.bodyMedium,
      decoration: base.copyWith(
        labelText: label,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
    final Widget wrappedField = errorText != null && errorText!.isNotEmpty
        ? Semantics(label: label, hint: errorText, child: field)
        : field;
    if (label == null) {
      return wrappedField;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label!, style: AppTypography.chipLabel(textTheme)),
        const SizedBox(height: 8),
        wrappedField,
      ],
    );
  }
}
