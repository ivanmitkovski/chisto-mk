import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Escape hatch for feature forms that need custom [InputDecoration] beyond [AppTextField].
class DesignSystemTextField extends StatelessWidget {
  const DesignSystemTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration,
    this.style,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.sentences,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.readOnly = false,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.buildCounter,
    this.textAlignVertical,
    this.scrollPadding,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextStyle? style;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final int? maxLength;
  final int maxLines;
  final int? minLines;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final InputCounterWidgetBuilder? buildCounter;
  final TextAlignVertical? textAlignVertical;
  final EdgeInsets? scrollPadding;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: decoration,
      style: style,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: minLines,
      readOnly: readOnly,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      inputFormatters: inputFormatters,
      buildCounter: buildCounter,
      textAlignVertical: textAlignVertical,
      scrollPadding: scrollPadding ?? const EdgeInsets.all(20),
    );
  }
}
