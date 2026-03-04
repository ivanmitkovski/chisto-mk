import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';

/// Chisto.mk app theme configuration.
/// Extend with Figma design tokens as you implement.
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        scaffoldBackgroundColor: AppColors.appBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.appBackground,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        textTheme: AppTypography.textTheme,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputFill,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: AppColors.error),
          ),
        ),
        useMaterial3: true,
      );
}
