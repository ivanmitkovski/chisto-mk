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

  static ThemeData get light => _build(Brightness.light);

  /// Dark theme stub. Currently identical surfaces to [light] until a full
  /// dark palette lands; isolated here so consumers can wire `darkTheme:` +
  /// `themeMode:` today without code churn when the palette ships.
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
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
      brightness: brightness,
      scaffoldBackgroundColor: AppColors.appBackground,
      fontFamily: robotoFamily,
      textTheme: textTheme,
      primaryTextTheme: primaryTextTheme,
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
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
    final TextTheme tt = GoogleFonts.robotoTextTheme(AppTypography.textTheme);
    return CupertinoTextThemeData(
      primaryColor: AppColors.primaryDark,
      textStyle: tt.bodyLarge?.copyWith(height: 1.36),
      actionTextStyle: tt.bodyLarge?.copyWith(
        color: AppColors.primaryDark,
        height: 1.36,
      ),
      actionSmallTextStyle: tt.titleSmall?.copyWith(
        color: AppColors.primaryDark,
        height: 1.33,
      ),
      tabLabelTextStyle: tt.bodySmall?.copyWith(
        fontSize: 10,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.24,
      ),
      navTitleTextStyle: tt.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.41,
        height: 1.29,
      ),
      navLargeTitleTextStyle: tt.headlineLarge?.copyWith(
        height: 1.12,
        letterSpacing: 0.37,
      ),
      navActionTextStyle: tt.bodyLarge?.copyWith(
        color: AppColors.primaryDark,
        height: 1.29,
      ),
      pickerTextStyle: tt.titleMedium?.copyWith(
        fontWeight: FontWeight.w400,
        height: 1.19,
      ),
      dateTimePickerTextStyle: tt.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
