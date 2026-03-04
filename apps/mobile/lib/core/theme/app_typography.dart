import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';

class AppTypography {
  const AppTypography._();

  static const TextTheme textTheme = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: -0.4,
    ),
    headlineMedium: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: -0.3,
    ),
    titleLarge: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: -0.2,
    ),
    titleMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
      height: 1.4,
    ),
    bodySmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textMuted,
    ),
    labelLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
  );

  // Auth & screen-specific helpers for consistent styling.
  static const TextStyle authHeadline = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
  );

  static const TextStyle authSubtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle pillLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}
