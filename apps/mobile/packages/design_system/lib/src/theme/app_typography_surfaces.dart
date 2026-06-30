import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Feature-surface typography helpers (home, reports, profile, notifications).
abstract final class AppTypographySurfaces {
  const AppTypographySurfaces._();

  // ---------------------------------------------------------------------------
  // Home + profile vertical — prefer [Theme.of] TextTheme.
  // ---------------------------------------------------------------------------

  /// Section label on home sheets (filters, grouped controls).
  static TextStyle homeSheetSectionLabel(TextTheme theme) =>
      (theme.labelMedium ??
              theme.bodySmall ??
              AppTypography.textTheme.bodySmall!)
          .copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          );

  /// Trailing action on section headers (Clear, See all).
  static TextStyle sectionHeaderAction(TextTheme theme) =>
      (theme.labelSmall ??
              theme.bodySmall ??
              AppTypography.textTheme.bodySmall!)
          .copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
            letterSpacing: 0.05,
          );

  /// Search input text in home map/search surfaces.
  static TextStyle homeSearchFieldText(TextTheme theme) =>
      (theme.bodyLarge ?? AppTypography.textTheme.bodyLarge!).copyWith(
        color: AppColors.textPrimary,
      );

  /// Placeholder text for home search fields.
  static TextStyle homeSearchFieldPlaceholder(TextTheme theme) =>
      (theme.bodyLarge ?? AppTypography.textTheme.bodyLarge!).copyWith(
        color: AppColors.textMuted,
      );

  /// Group label used across profile/home settings sections.
  static TextStyle homeSettingsGroupLabel(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      );

  /// Muted small caption text used on home/profile surfaces.
  static TextStyle homeMutedCaption(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: AppColors.textMuted,
      );

  // ---------------------------------------------------------------------------
  // Reports vertical — prefer [Theme.of] for Roboto + dynamic type.
  // ---------------------------------------------------------------------------

  /// Report detail / sheet primary title (modal chrome).
  static TextStyle reportsSheetTitle(TextTheme theme) =>
      (theme.titleMedium ?? AppTypography.textTheme.titleMedium!).copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      );

  /// Subtitle under the sheet title (moderation context line).
  static TextStyle reportsSheetSubtitle(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: AppColors.textMuted,
        height: 1.35,
      );

  /// Section header inside report body (e.g. narrative title).
  static TextStyle reportsSectionHeader(TextTheme theme) =>
      (theme.titleSmall ?? AppTypography.textTheme.titleSmall!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      );

  /// Left column label in detail rows (Category, Severity, …).
  static TextStyle reportsRowLabel(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
      );

  /// Right column value in detail rows.
  static TextStyle reportsRowValue(TextTheme theme) =>
      (theme.bodyMedium ?? AppTypography.textTheme.bodyMedium!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Emphasized numeric value (e.g. points).
  static TextStyle reportsRowValueStrong(TextTheme theme) => reportsRowValue(
    theme,
  ).copyWith(fontWeight: FontWeight.w700, color: AppColors.accentWarning);

  /// Small pill label on report cards / detail chips.
  static TextStyle reportsPillLabel(TextTheme theme) =>
      (theme.labelSmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      );

  /// Status badge on list cards (compact).
  static TextStyle reportsBadgeLabel(TextTheme theme) =>
      (theme.labelSmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );

  /// [ReportInfoBanner] title line.
  static TextStyle reportsBannerTitle(TextTheme theme) =>
      (theme.titleSmall ?? AppTypography.textTheme.titleSmall!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// [ReportInfoBanner] body copy.
  static TextStyle reportsBannerBody(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: AppColors.textSecondary,
        height: 1.35,
        fontWeight: FontWeight.w400,
      );

  /// Caption on evidence gallery glass pill (“Open photo”, “Tap to expand”).
  static TextStyle reportsGalleryHint(TextTheme theme) =>
      (theme.labelSmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        fontWeight: FontWeight.w500,
        color: AppColors.textOnDark,
      );

  /// Dense `12/60`-style counters beside report form fields (Dynamic Type friendly).
  static TextStyle reportsCharCounter(TextTheme theme) =>
      (theme.labelSmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w500,
      );

  /// Section labels in the new-report details step (category, severity, title…).
  static TextStyle reportsFormFieldLabel(TextTheme theme, {Color? color}) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: color ?? AppColors.textSecondary,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      );

  /// Current severity readout above the slider track.
  static TextStyle reportsSliderValue(TextTheme theme) =>
      (theme.bodyMedium ?? AppTypography.textTheme.bodyMedium!).copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      );

  /// Primary CTA label on the new-report bottom bar.
  static TextStyle reportsBottomBarButtonLabel(TextTheme theme) =>
      (theme.labelLarge ?? AppTypography.textTheme.labelLarge!).copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      );

  /// Validation hint under the evidence photo grid.
  static TextStyle reportsEvidenceValidationHint(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: AppColors.accentDanger,
        height: 1.35,
      );

  /// Compact address line under the location map.
  static TextStyle reportsLocationAddressBadge(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.25,
      );

  // ---------------------------------------------------------------------------
  // Profile vertical
  // ---------------------------------------------------------------------------

  /// Settings section labels (account, support, safety).
  static TextStyle profileSettingsSectionLabel(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      );

  /// Field label above profile form inputs.
  static TextStyle profileFormFieldLabel(TextTheme theme) =>
      profileSettingsSectionLabel(theme);

  /// Muted helper under read-only profile fields.
  static TextStyle profileFormFieldHint(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: AppColors.textMuted,
        height: 1.35,
      );

  /// Profile header username subtitle.
  static TextStyle profileHeaderSubtitle(TextTheme theme) =>
      homeMutedCaption(theme);

  static TextStyle profileAvatarCaption(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
      );

  static TextStyle reportsListFilterActive(TextTheme theme) =>
      (theme.labelLarge ?? AppTypography.textTheme.labelLarge!).copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      );

  static TextStyle reportsLocationPickerHint(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: AppColors.textMuted,
        height: 1.35,
      );

  static TextStyle reportsOutboxBannerBody(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        height: 1.35,
        color: AppColors.textPrimary,
      );

  /// Password screen validation hint.
  static TextStyle profilePasswordHint(TextTheme theme) =>
      profileFormFieldHint(theme);

  /// General-info field hint style.
  static TextStyle profileGeneralInfoFieldHint(TextTheme theme) =>
      (theme.bodyMedium ?? AppTypography.textTheme.bodyMedium!).copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w400,
        height: 1.35,
      );

  static TextStyle profileHeaderPhoneOnDark(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: AppColors.textOnDarkMuted,
      );

  static TextStyle profilePointsHistoryDayHeader(TextTheme theme) =>
      (theme.labelLarge ?? AppTypography.textTheme.labelLarge!).copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      );

  /// Points history activity primary line.
  static TextStyle profilePointsActivityTitle(TextTheme theme) =>
      (theme.bodyMedium ?? AppTypography.textTheme.bodyMedium!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Points history activity secondary line.
  static TextStyle profilePointsActivitySubtitle(TextTheme theme) =>
      homeMutedCaption(theme);

  /// Points delta on activity tiles.
  static TextStyle profilePointsActivityValue(TextTheme theme) =>
      (theme.titleSmall ?? AppTypography.textTheme.titleSmall!).copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.primaryDark,
      );

  /// Milestone chip title.
  static TextStyle profileMilestoneChipTitle(TextTheme theme) =>
      (theme.labelSmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Milestone chip body.
  static TextStyle profileMilestoneChipBody(TextTheme theme) =>
      homeMutedCaption(theme);

  /// Milestone chip meta line.
  static TextStyle profileMilestoneChipMeta(TextTheme theme) =>
      (theme.labelSmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
      );

  /// Summary strip primary value.
  static TextStyle profilePointsSummaryValue(TextTheme theme) =>
      (theme.bodyMedium ?? AppTypography.textTheme.bodyMedium!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Weekly ranking display name.
  static TextStyle profileWeeklyRankName(TextTheme theme) =>
      (theme.bodyMedium ?? AppTypography.textTheme.bodyMedium!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Weekly ranking points column.
  static TextStyle profileWeeklyRankPoints(TextTheme theme) =>
      profileWeeklyRankName(theme);

  /// Highlighted current-user row caption.
  static TextStyle profileWeeklyCurrentUserCaption(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w600,
      );

  /// Points history screen CTA label.
  static TextStyle profilePointsHistoryCta(TextTheme theme) =>
      (theme.labelLarge ?? AppTypography.textTheme.labelLarge!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.primaryDark,
      );

  // ---------------------------------------------------------------------------
  // Notifications vertical
  // ---------------------------------------------------------------------------

  static TextStyle notificationsScreenTitle(TextTheme theme) =>
      (theme.titleLarge ?? AppTypography.textTheme.titleLarge!).copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      );

  static TextStyle notificationsScreenSubtitle(TextTheme theme) =>
      homeMutedCaption(theme);

  static TextStyle notificationsFilterChip(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        fontWeight: FontWeight.w600,
      );

  static TextStyle notificationsUnreadBanner(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      );

  static TextStyle notificationsSwipeHint(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: AppColors.textMuted.withValues(alpha: 0.85),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      );

  static TextStyle notificationsEmptyTitle(TextTheme theme) =>
      (theme.titleSmall ?? AppTypography.textTheme.titleSmall!).copyWith(
        fontWeight: FontWeight.w600,
      );

  static TextStyle notificationsErrorTitle(TextTheme theme) =>
      (theme.titleSmall ?? AppTypography.textTheme.titleSmall!).copyWith(
        fontWeight: FontWeight.w700,
      );

  // ---------------------------------------------------------------------------
  // Home feed / map / site detail (additional helpers)
  // ---------------------------------------------------------------------------

  static TextStyle homeNotificationBadge(TextTheme theme, double fontSize) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: AppColors.textOnDark,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        height: 1,
      );

  static TextStyle homeNotificationTileTitle(
    TextTheme theme, {
    required bool unread,
  }) => (theme.bodyMedium ?? AppTypography.textTheme.bodyMedium!).copyWith(
    fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
    height: 1.2,
  );

  static TextStyle homeNotificationTileBody(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: AppColors.textSecondary,
        height: 1.25,
      );

  static TextStyle homeNotificationTileGroupCount(
    TextTheme theme, {
    required Color color,
  }) => (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
    color: color,
    fontWeight: FontWeight.w600,
    fontSize: 11,
  );

  static TextStyle homeNotificationDayHeader(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  static TextStyle homeCleaningErrorBody(
    TextTheme theme, {
    required Color color,
  }) => (theme.bodyMedium ?? AppTypography.textTheme.bodyMedium!).copyWith(
    color: color,
  );

  static TextStyle homeCleaningEmptyTitle(TextTheme theme) =>
      (theme.bodyLarge ?? AppTypography.textTheme.bodyLarge!).copyWith(
        fontWeight: FontWeight.w600,
      );

  static TextStyle homeCleaningEmptyBody(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        height: 1.45,
      );

  static TextStyle homeCleaningEmptyCta(
    TextTheme theme, {
    required Color color,
  }) => (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
    color: color,
    fontWeight: FontWeight.w600,
  );

  static TextStyle homeNotificationTileTimestamp(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: AppColors.textMuted,
        fontSize: 12,
      );

  static TextStyle homeSitePreviewStatusChip(
    TextTheme theme, {
    required Color color,
  }) => (theme.labelSmall ?? AppTypography.textTheme.bodySmall!).copyWith(
    color: color,
    fontWeight: FontWeight.w600,
    fontSize: 11,
  );

  static TextStyle homeSitePreviewActionPill(
    TextTheme theme, {
    required Color color,
  }) => (theme.labelMedium ?? AppTypography.textTheme.labelLarge!).copyWith(
    color: color,
    fontWeight: FontWeight.w600,
    fontSize: 12,
  );

  static TextStyle homeMapFilterCounter(
    TextTheme theme, {
    required Color color,
  }) => (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
    color: color,
    fontWeight: FontWeight.w600,
    fontSize: 13,
  );

  static TextStyle homeReportIssueReasonTitle(
    TextTheme theme, {
    required Color color,
  }) => (theme.bodyMedium ?? AppTypography.textTheme.bodyMedium!).copyWith(
    fontWeight: FontWeight.w600,
    color: color,
  );

  static TextStyle profilePointsDelta(
    TextTheme theme, {
    required Color color,
  }) => (theme.titleSmall ?? AppTypography.textTheme.titleSmall!).copyWith(
    color: color,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static TextStyle homeMapMenuCaption(TextTheme theme) =>
      homeMutedCaption(theme);

  static TextStyle homeMapOverlayTitle(
    TextTheme theme, {
    required Color color,
  }) => (theme.titleMedium ?? AppTypography.textTheme.titleMedium!).copyWith(
    color: color,
    fontWeight: FontWeight.w600,
  );

  static TextStyle homeMapOverlayBody(
    TextTheme theme, {
    required Color color,
  }) => (theme.bodyMedium ?? AppTypography.textTheme.bodyMedium!).copyWith(
    color: color,
  );

  static TextStyle homeCleaningEventsVolunteerCount(
    TextTheme theme, {
    required Color color,
  }) => (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
    fontWeight: FontWeight.w500,
    fontSize: 13,
    color: color,
  );

  static TextStyle homeCleaningEventsHint(
    TextTheme theme, {
    required Color color,
  }) => (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
    color: color,
    height: 1.35,
  );

  static TextStyle profileMilestoneLevelBadge(TextTheme theme) =>
      (theme.labelSmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        fontSize: 9,
      );

  static TextStyle profileMilestoneTitle(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        height: 1.15,
      );

  static TextStyle reportsPhotoGridCount(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      );

  static TextStyle reportsDetailsFieldValue(TextTheme theme) =>
      (theme.bodyMedium ?? AppTypography.textTheme.bodyMedium!).copyWith(
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      );

  static TextStyle reportsDetailsFieldHint(TextTheme theme) =>
      (theme.bodyMedium ?? AppTypography.textTheme.bodyMedium!).copyWith(
        color: AppColors.textMuted.withValues(alpha: 0.85),
        fontWeight: FontWeight.w400,
        letterSpacing: -0.15,
      );

  static TextStyle homeCommentsComposerCounter(
    TextTheme theme, {
    required Color color,
  }) => (theme.labelSmall ?? AppTypography.textTheme.bodySmall!).copyWith(
    color: color,
  );

  static TextStyle homeCommentsComposerField(
    TextTheme theme, {
    required bool mentionActive,
  }) => (theme.bodyMedium ?? AppTypography.textTheme.bodyMedium!).copyWith(
    color: mentionActive ? AppColors.primaryDark : AppColors.textPrimary,
    fontWeight: mentionActive ? FontWeight.w600 : FontWeight.w400,
  );

  static TextStyle reportsPhotoGalleryPill(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        fontWeight: FontWeight.w500,
        color: AppColors.textOnDark,
        letterSpacing: -0.1,
      );

  static TextStyle homeCoReportersTitle(TextTheme theme) =>
      (theme.titleMedium ?? AppTypography.textTheme.titleMedium!).copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      );

  static TextStyle homeCoReportersSubtitle(TextTheme theme) =>
      homeMutedCaption(theme);

  static TextStyle homeFirstReportTitle(TextTheme theme) =>
      (theme.titleSmall ?? AppTypography.textTheme.titleSmall!).copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      );

  static TextStyle homeFirstReportBody(TextTheme theme) =>
      (theme.bodyMedium ?? AppTypography.textTheme.bodyMedium!).copyWith(
        color: AppColors.textSecondary,
        height: 1.45,
      );

  static TextStyle homeCleaningEventsCaption(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w500,
      );

  static TextStyle homeCleaningEventsMeta(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: AppColors.textMuted,
        height: 1.4,
      );

  static TextStyle homeHistoryStatusCaption(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );

  static TextStyle homeMergedDuplicateBody(TextTheme theme) =>
      (theme.bodyMedium ?? AppTypography.textTheme.bodyMedium!).copyWith(
        color: AppColors.textSecondary,
        height: 1.45,
      );

  static TextStyle homeReportIssueLabel(TextTheme theme) =>
      (theme.bodyMedium ?? AppTypography.textTheme.bodyMedium!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle homeReportIssueBody(TextTheme theme) =>
      (theme.bodyMedium ?? AppTypography.textTheme.bodyMedium!).copyWith(
        color: AppColors.textPrimary,
        height: 1.45,
      );

  static TextStyle homeReportIssueCaption(TextTheme theme) =>
      homeMutedCaption(theme);

  static TextStyle reportsListFilterLabel(TextTheme theme) =>
      (theme.labelLarge ?? AppTypography.textTheme.labelLarge!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle reportsLocationPickerCaption(TextTheme theme) =>
      homeMutedCaption(theme);

  static TextStyle reportsPhotoGridHint(TextTheme theme) =>
      homeMutedCaption(theme);

  static TextStyle reportsPhotoGridValidation(TextTheme theme) =>
      reportsEvidenceValidationHint(theme);

  static TextStyle reportsOutboxBanner(TextTheme theme) =>
      (theme.bodySmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        color: AppColors.textSecondary,
        height: 1.35,
      );

  static TextStyle reportsBottomBarStep(TextTheme theme) =>
      (theme.labelSmall ?? AppTypography.textTheme.bodySmall!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
      );

  static TextStyle reportsMapTilesFallback(TextTheme theme) =>
      homeMutedCaption(theme);
}
