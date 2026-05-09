import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

/// Outline [InputDecoration] matching [AppTheme.light] `inputDecorationTheme`
/// (pill radius, fill, borders, padding tokens).
InputDecoration appOutlineInputDecoration() {
  final BorderRadius radius = BorderRadius.circular(AppSpacing.radiusPill);
  final OutlineInputBorder enabled = OutlineInputBorder(
    borderRadius: radius,
    borderSide: const BorderSide(color: AppColors.inputBorder),
  );
  return InputDecoration(
    filled: true,
    fillColor: AppColors.inputFill,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.inputPaddingHorizontal,
      vertical: AppSpacing.inputPaddingVertical,
    ),
    border: enabled,
    enabledBorder: enabled,
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppColors.primary),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppColors.error),
    ),
  );
}
