import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';

/// Character counter aligned to the trailing edge of a text field.
Widget editEventLengthCounter(
  TextTheme textTheme,
  int currentLength,
  int maxLength,
) {
  return Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Align(
      alignment: Alignment.centerRight,
      child: Text(
        '$currentLength/$maxLength',
        style: AppTypography.eventsListCardMeta(textTheme).copyWith(height: 1.0),
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
    floatingLabelStyle: AppTypography.eventsListCardMeta(textTheme).copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 13,
      height: 1.15,
    ),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 14,
    ),
  );
}
