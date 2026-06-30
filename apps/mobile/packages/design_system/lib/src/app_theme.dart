import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_spacing.dart';
import 'package:design_system/src/theme/app_typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Chisto.mk app theme configuration.
/// Extend with Figma design tokens as you implement.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build();

  static ThemeData _build() {
    const Brightness brightness = Brightness.light;
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      surface: AppColors.appBackground,
    );
    final TextTheme textTheme = GoogleFonts.robotoTextTheme(
      AppTypography.textTheme,
    );
    final TextTheme primaryTextTheme =
        GoogleFonts.robotoTextTheme(AppTypography.textTheme).apply(
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
        textTheme: _cupertinoRobotoTextTheme(textTheme),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.appBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.eventsScreenTitle(textTheme),
        toolbarTextStyle: textTheme.bodyLarge,
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: AppTypography.chipLabel(textTheme),
        unselectedLabelStyle: AppTypography.cardSubtitle(textTheme),
        labelColor: AppColors.primaryDark,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((
          Set<WidgetState> states,
        ) {
          final TextStyle base = AppTypography.badgeLabel(textTheme);
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(color: AppColors.primaryDark);
          }
          return base.copyWith(color: AppColors.textMuted);
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedLabelStyle: AppTypography.badgeLabel(
          textTheme,
        ).copyWith(color: AppColors.primaryDark),
        unselectedLabelStyle: AppTypography.badgeLabel(
          textTheme,
        ).copyWith(color: AppColors.textMuted),
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.appBackground,
        titleTextStyle: AppTypography.sheetTitle(textTheme),
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textOnDark,
        ),
        backgroundColor: AppColors.textPrimary,
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: AppTypography.cardTitle(textTheme),
        subtitleTextStyle: AppTypography.cardSubtitle(textTheme),
      ),
      chipTheme: ChipThemeData(
        labelStyle: AppTypography.chipLabel(textTheme),
        secondaryLabelStyle: AppTypography.chipLabel(textTheme),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: AppTypography.buttonLabel(
            textTheme,
          ).copyWith(color: AppColors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: AppTypography.buttonLabel(textTheme),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: AppTypography.pillLabel(
            textTheme,
          ).copyWith(color: AppColors.primaryDark),
        ),
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
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        labelStyle: AppTypography.eventsFormFieldLabel(textTheme),
        floatingLabelStyle: AppTypography.eventsFormFieldLabel(textTheme),
        errorStyle: AppTypography.eventsFormError(textTheme),
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
  static CupertinoTextThemeData _cupertinoRobotoTextTheme(TextTheme tt) {
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
