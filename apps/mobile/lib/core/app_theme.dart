import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';

/// Chisto.mk app theme configuration.
/// Extend with Figma design tokens as you implement.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.appBackground,
    );
    final TextTheme textTheme =
        GoogleFonts.robotoTextTheme(AppTypography.textTheme);
    final TextTheme primaryTextTheme = GoogleFonts.robotoTextTheme(
      AppTypography.textTheme,
    ).apply(
      bodyColor: colorScheme.onPrimary,
      displayColor: colorScheme.onPrimary,
    );
    final String? robotoFamily = GoogleFonts.roboto().fontFamily;

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.appBackground,
      fontFamily: robotoFamily,
      textTheme: textTheme,
      primaryTextTheme: primaryTextTheme,
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.appBackground,
        barBackgroundColor: AppColors.appBackground,
        textTheme: _cupertinoRobotoTextTheme(),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.inputPaddingHorizontal,
          vertical: AppSpacing.inputPaddingVertical,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      useMaterial3: true,
      bottomSheetTheme: const BottomSheetThemeData(
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  /// Cupertino widgets ([CupertinoSearchTextField], pickers) read this instead of
  /// [ThemeData.textTheme]; mirror stock weights/sizes with Roboto.
  static CupertinoTextThemeData _cupertinoRobotoTextTheme() {
    return CupertinoTextThemeData(
      primaryColor: AppColors.primaryDark,
      textStyle: GoogleFonts.roboto(
        fontSize: 17,
        height: 1.36,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      actionTextStyle: GoogleFonts.roboto(
        fontSize: 17,
        height: 1.36,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryDark,
      ),
      actionSmallTextStyle: GoogleFonts.roboto(
        fontSize: 15,
        height: 1.33,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryDark,
      ),
      tabLabelTextStyle: GoogleFonts.roboto(
        fontSize: 10,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.24,
        color: AppColors.textSecondary,
      ),
      navTitleTextStyle: GoogleFonts.roboto(
        fontSize: 17,
        height: 1.29,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.41,
        color: AppColors.textPrimary,
      ),
      navLargeTitleTextStyle: GoogleFonts.roboto(
        fontSize: 34,
        height: 1.12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.37,
        color: AppColors.textPrimary,
      ),
      navActionTextStyle: GoogleFonts.roboto(
        fontSize: 17,
        height: 1.29,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryDark,
      ),
      pickerTextStyle: GoogleFonts.roboto(
        fontSize: 21,
        height: 1.19,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      dateTimePickerTextStyle: GoogleFonts.roboto(
        fontSize: 16,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
