import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_radii.dart';
import 'package:design_system/src/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Multiline composer for event chat (pill outline, no Material [TextField] in features).
class EventsChatComposerField extends StatelessWidget {
  const EventsChatComposerField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.enabled = true,
    this.minLines = 1,
    this.maxLines = 5,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool enabled;
  final int minLines;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      minLines: minLines,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.newline,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: AppRadii.pill,
          borderSide: BorderSide(
            color: AppColors.inputBorder.withValues(alpha: 0.35),
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.pill,
          borderSide: BorderSide(
            color: AppColors.inputBorder.withValues(alpha: 0.35),
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.pill,
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        isDense: true,
      ),
    );
  }
}
