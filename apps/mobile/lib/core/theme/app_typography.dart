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
    titleSmall: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: -0.2,
      height: 1.25,
    ),
    labelLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
  );

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

  static const TextStyle sectionHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static const TextStyle chipLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const TextStyle sheetTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle badgeLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  static const TextStyle emptyStateTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle emptyStateSubtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.5,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  // ---------------------------------------------------------------------------
  // Events vertical — prefer [TextTheme] from [Theme.of] for dynamic type.
  // ---------------------------------------------------------------------------

  /// Detail screen: primary title under the hero (one dominant headline).
  static TextStyle eventsDetailHeadline(TextTheme theme) =>
      (theme.headlineMedium ?? textTheme.headlineMedium!).copyWith(
        letterSpacing: -0.5,
        height: 1.15,
      );

  /// List / card row: event title in feed and similar dense layouts.
  static TextStyle eventsListCardTitle(TextTheme theme) =>
      (theme.titleSmall ?? textTheme.titleSmall!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  /// Compact secondary line: time range, meta on cards.
  static TextStyle eventsListCardMeta(TextTheme theme) =>
      (theme.bodySmall ?? textTheme.bodySmall!).copyWith(
        color: AppColors.textMuted,
      );

  /// Hero / gradient card: title over imagery.
  static TextStyle eventsHeroCardTitle(TextTheme theme) =>
      (theme.titleMedium ?? textTheme.titleMedium!).copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        height: 1.2,
        letterSpacing: -0.3,
      );

  /// Hero / gradient card: location and time captions.
  static TextStyle eventsHeroCardMeta(TextTheme theme) =>
      (theme.bodySmall ?? textTheme.bodySmall!).copyWith(
        color: AppColors.textOnDarkMuted,
        fontWeight: FontWeight.w500,
      );

  /// Detail section headers (matches [DetailSectionHeader] weight; scales with theme).
  static TextStyle eventsSectionTitle(TextTheme theme) =>
      (theme.titleSmall ?? textTheme.titleSmall!).copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      );

  /// Schedule line under detail title.
  static TextStyle eventsDetailScheduleLine(TextTheme theme) =>
      (theme.bodyMedium ?? textTheme.bodyMedium!).copyWith(
        color: AppColors.textMuted,
        height: 1.35,
      );

  /// Create/edit picker value row.
  static TextStyle eventsFormFieldValue(TextTheme theme, {required bool hasValue}) =>
      (theme.bodyMedium ?? textTheme.bodyMedium!).copyWith(
        color: hasValue ? AppColors.textPrimary : AppColors.textMuted,
      );
}
