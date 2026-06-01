import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Character counter aligned to the trailing edge of a text field.
Widget editEventLengthCounter(
  TextTheme textTheme,
  int currentLength,
  int maxLength,
) {
  return Padding(
    padding: const EdgeInsets.only(top: AppSpacing.radiusHandle),
    child: Align(
      alignment: Alignment.centerRight,
      child: Text(
        '$currentLength/$maxLength',
        style: AppTypography.eventsListCardMeta(textTheme).copyWith(height: 1),
      ),
    ),
  );
}

/// Shared decoration for edit-event multiline and numeric fields.
InputDecoration editEventTextFieldDecoration(
  TextTheme textTheme, {
  required String labelText,
  String? hintText,
  String? errorText,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    errorText: errorText,
    labelStyle: AppTypography.eventsCalendarSectionHeader(textTheme),
    floatingLabelStyle: AppTypography.eventsListCardMeta(
      textTheme,
    ).copyWith(fontWeight: FontWeight.w600, fontSize: 13, height: 1.15),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 14,
    ),
  );
}
