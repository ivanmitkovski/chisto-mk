import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';

/// Design-time text styles for Chisto mobile.
///
/// Typeface: [AppTheme] applies **Roboto** on iOS and Android via `google_fonts`
/// (`GoogleFonts.robotoTextTheme`); this file defines sizes, weights, and colors only.
///
/// **Dynamic Type (text scaling)** — Prefer widgets that inherit the ambient
/// [TextScaler] (default [Text] behavior). When a layout would overflow at large
/// accessibility sizes, wrap that subtree with
/// `MediaQuery.textScalerOf(context).clamp(maxScaleFactor: …)` and document why
/// that surface is capped (e.g. dense chat bubbles). Do not clamp app-wide.
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
  static TextStyle eventsFormFieldValue(
    TextTheme theme, {
    required bool hasValue,
  }) => (theme.bodyMedium ?? textTheme.bodyMedium!).copyWith(
    color: hasValue ? AppColors.textPrimary : AppColors.textMuted,
  );

  // --- Sheets & modal surfaces ---

  /// Modal / bottom sheet primary title (filter, picker chrome).
  static TextStyle eventsSheetTitle(TextTheme theme) =>
      (theme.titleMedium ?? textTheme.titleMedium!).copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      );

  /// Tertiary action in sheet header (e.g. Clear all).
  static TextStyle eventsSheetTextLink(TextTheme theme) =>
      (theme.bodySmall ?? textTheme.bodySmall!).copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      );

  /// Inline text action at body size (reminder toggle, row actions).
  static TextStyle eventsTextLinkEmphasis(TextTheme theme) =>
      (theme.bodyMedium ?? textTheme.bodyMedium!).copyWith(
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w600,
      );

  /// Uppercase-style section label in sheets and long forms.
  static TextStyle eventsSheetSectionLabel(TextTheme theme) =>
      (theme.labelMedium ?? theme.bodySmall ?? textTheme.bodySmall!).copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.35,
      );

  /// Filter / toggle chip label inside sheets.
  static TextStyle eventsSheetChipLabel(
    TextTheme theme, {
    required bool selected,
    required Color accent,
  }) => (theme.bodySmall ?? textTheme.bodySmall!).copyWith(
    color: selected ? accent : AppColors.textSecondary,
    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
  );

  /// Small label above a compact value cell (date tiles, form rows).
  static TextStyle eventsSheetDateTileLabel(TextTheme theme) =>
      (theme.labelSmall ?? theme.bodySmall ?? textTheme.bodySmall!).copyWith(
        color: AppColors.textMuted,
      );

  static TextStyle eventsSheetDateTileValue(
    TextTheme theme, {
    required bool hasValue,
  }) => (theme.bodySmall ?? textTheme.bodySmall!).copyWith(
    color: hasValue ? AppColors.textPrimary : AppColors.textMuted,
    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
  );

  /// Primary filled button label on green (filters, confirmations).
  static TextStyle eventsPrimaryButtonLabel(TextTheme theme) =>
      (theme.labelLarge ?? textTheme.labelLarge!).copyWith(
        color: AppColors.white,
        fontWeight: FontWeight.w600,
      );

  /// Outlined / secondary CTA on detail sticky bar.
  static TextStyle eventsSecondaryCtaLabel(TextTheme theme) =>
      (theme.titleMedium ?? textTheme.titleMedium!).copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      );

  // --- Detail & feed body ---

  /// Long-form description and markdown-like blocks on detail.
  static TextStyle eventsBodyProse(TextTheme theme) =>
      (theme.bodyMedium ?? textTheme.bodyMedium!).copyWith(
        color: AppColors.textPrimary,
        height: 1.42,
      );

  /// Slightly looser body for rich descriptions (markdown blocks).
  static TextStyle eventsBodyProseRelaxed(TextTheme theme) =>
      eventsBodyProse(theme).copyWith(height: 1.55);

  /// Muted paragraph (supporting copy under a headline).
  static TextStyle eventsBodyMuted(TextTheme theme) =>
      (theme.bodyMedium ?? textTheme.bodyMedium!).copyWith(
        color: AppColors.textMuted,
        height: 1.35,
      );

  /// Secondary emphasis at body size (category row, subdued labels).
  static TextStyle eventsBodyMediumSecondary(TextTheme theme) =>
      (theme.bodyMedium ?? textTheme.bodyMedium!).copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      );

  /// Property name in grids (Organizer, Site, …).
  static TextStyle eventsInlineLabel(TextTheme theme) =>
      (theme.bodySmall ?? textTheme.bodySmall!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
      );

  static TextStyle eventsGridPropertyValue(TextTheme theme) =>
      (theme.bodySmall ?? textTheme.bodySmall!).copyWith(
        color: AppColors.textSecondary,
      );

  /// Emphasized single-line caption (badges, callouts).
  static TextStyle eventsCaptionStrong(TextTheme theme, {Color? color}) =>
      (theme.bodySmall ?? textTheme.bodySmall!).copyWith(
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textSecondary,
      );

  /// Compact panel title inside detail surfaces (e.g. trash bags editor).
  static TextStyle eventsPanelTitle(TextTheme theme) =>
      (theme.bodyLarge ?? textTheme.bodyLarge!).copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// Primary line in grouped rows (recurrence picker, compact summaries).
  static TextStyle eventsGroupedRowPrimary(TextTheme theme) =>
      (theme.bodyMedium ?? textTheme.bodyMedium!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Primary line on tinted callout surfaces (check-in banner, info panels).
  static TextStyle eventsCalloutTitle(TextTheme theme) =>
      (theme.titleSmall ?? textTheme.titleSmall!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle eventsCalloutSubtitle(TextTheme theme) =>
      (theme.bodySmall ?? textTheme.bodySmall!).copyWith(
        color: AppColors.textSecondary,
      );

  // --- Card rows & list adornments ---

  /// Accent badge on event cards (e.g. checked-in).
  static TextStyle eventsCardBadgeAccent(
    TextTheme theme, {
    required Color color,
  }) => (theme.labelSmall ?? theme.bodySmall ?? textTheme.bodySmall!).copyWith(
    color: color,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// Neutral micro-line on cards (photo count, meta).
  static TextStyle eventsCardBadgeMuted(TextTheme theme) =>
      (theme.labelSmall ?? theme.bodySmall ?? textTheme.bodySmall!).copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w500,
        height: 1.2,
      );

  // --- Metrics & stats ---

  static TextStyle eventsMetricValue(TextTheme theme) =>
      (theme.bodyLarge ?? textTheme.bodyLarge!).copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.15,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      );

  /// Large numeric stat (impact, trash bags).
  static TextStyle eventsDisplayStat(TextTheme theme) =>
      (theme.headlineSmall ?? theme.titleLarge ?? textTheme.titleLarge!)
          .copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.35,
            height: 1.08,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          );

  /// Large colored percentage (organizer analytics ring context).
  static TextStyle eventsAnalyticsHeroMetric(
    TextTheme theme, {
    required Color color,
  }) => (theme.headlineMedium ?? textTheme.headlineMedium!).copyWith(
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: color,
  );

  // --- Forms (create / edit) ---

  /// Same visual as [eventsSheetSectionLabel]; use in stepped forms.
  static TextStyle eventsFormSectionLabel(TextTheme theme) =>
      eventsSheetSectionLabel(theme);

  /// Stepped form section title (bodyLarge emphasis).
  static TextStyle eventsFormLeadHeading(TextTheme theme) =>
      (theme.bodyLarge ?? textTheme.bodyLarge!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle eventsFormFieldLabel(TextTheme theme) =>
      (theme.bodySmall ?? textTheme.bodySmall!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );

  static TextStyle eventsFormError(TextTheme theme) =>
      (theme.bodySmall ?? textTheme.bodySmall!).copyWith(
        color: AppColors.error,
        fontWeight: FontWeight.w500,
      );

  /// Prominent numeric value in form rows (steppers, counters).
  static TextStyle eventsFormCounterValue(TextTheme theme) =>
      theme.titleSmall ?? textTheme.titleSmall!;

  /// Edit-event primary text fields (title, numeric caps).
  static TextStyle eventsEditFormFieldPrimary(TextTheme theme) =>
      (theme.bodyLarge ?? textTheme.bodyLarge!).copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      );

  /// Pill count on chat row badge (light-on-primary).
  static TextStyle eventsUnreadCountBadge(TextTheme theme) =>
      (theme.labelSmall ?? textTheme.bodySmall!).copyWith(
        color: AppColors.textOnDark,
        fontWeight: FontWeight.w600,
      );

  /// Detail grouped row that uses [bodyLarge] (chat entry).
  static TextStyle eventsDetailAuxRowTitle(TextTheme theme) =>
      theme.bodyLarge ?? textTheme.bodyLarge!;

  /// Large clock readout in time-range picker blocks.
  static TextStyle eventsTimePickerClockValue(TextTheme theme) =>
      (theme.headlineLarge ?? textTheme.headlineLarge!).copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  // --- Chat ---

  static TextStyle eventsChatMessageBody(TextTheme theme, {Color? color}) =>
      (theme.bodyMedium ?? textTheme.bodyMedium!).copyWith(
        color: color ?? AppColors.textPrimary,
        height: 1.28,
      );

  static TextStyle eventsChatAuthorName(TextTheme theme) =>
      (theme.bodySmall ?? textTheme.bodySmall!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle eventsChatTimestamp(TextTheme theme, {Color? color}) =>
      (theme.labelSmall ?? theme.bodySmall ?? textTheme.bodySmall!).copyWith(
        color: color ?? AppColors.textMuted,
        height: 1.1,
      );

  static TextStyle eventsChatSystemLine(TextTheme theme) =>
      (theme.bodySmall ?? textTheme.bodySmall!).copyWith(
        color: AppColors.textMuted,
        height: 1.25,
      );

  // --- Check-in & QR ---

  static TextStyle eventsQrCaption(TextTheme theme) =>
      (theme.bodySmall ?? textTheme.bodySmall!).copyWith(
        color: AppColors.textMuted,
        height: 1.35,
      );

  /// Muted supporting line (calendar hints, footnotes) — same rhythm as [eventsQrCaption].
  static TextStyle eventsSupportingCaption(TextTheme theme) =>
      eventsQrCaption(theme);

  // --- Semantic ---

  static TextStyle eventsDestructiveCaption(TextTheme theme) =>
      (theme.bodySmall ?? textTheme.bodySmall!).copyWith(
        color: AppColors.accentDanger,
        fontWeight: FontWeight.w500,
      );

  static TextStyle eventsWarningCaption(TextTheme theme) =>
      (theme.bodySmall ?? textTheme.bodySmall!).copyWith(
        color: AppColors.accentWarningDark,
        fontWeight: FontWeight.w600,
      );

  /// Dense screen titles (feed toolbar, full-screen sections).
  static TextStyle eventsScreenTitle(TextTheme theme) =>
      (theme.titleLarge ?? textTheme.titleLarge!).copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      );

  // --- Feed & calendar ---

  /// Events feed large headline (matches prior headlineLarge + tracking).
  static TextStyle eventsFeedScreenTitle(TextTheme theme) =>
      (theme.headlineLarge ?? textTheme.headlineLarge!).copyWith(
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle eventsSearchFieldText(TextTheme theme) =>
      (theme.bodyMedium ?? textTheme.bodyMedium!).copyWith(
        color: AppColors.textPrimary,
      );

  static TextStyle eventsSearchFieldPlaceholder(TextTheme theme) =>
      (theme.bodyMedium ?? textTheme.bodyMedium!).copyWith(
        color: AppColors.textMuted,
      );

  /// Offline / info strip on feed.
  static TextStyle eventsInlineInfoBanner(TextTheme theme) =>
      (theme.bodySmall ?? textTheme.bodySmall!).copyWith(
        color: AppColors.textPrimary,
        height: 1.3,
      );

  /// Feed section headers (Happening now, Coming up).
  static TextStyle eventsFeedSectionTitle(TextTheme theme) =>
      (theme.titleMedium ?? textTheme.titleMedium!).copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      );

  static TextStyle eventsCalendarMonthTitle(TextTheme theme) =>
      (theme.titleMedium ?? textTheme.titleMedium!).copyWith(
        fontWeight: FontWeight.w600,
      );

  /// Compact month title in embedded [EventCalendar] chrome.
  static TextStyle eventsCalendarEmbeddedMonthTitle(TextTheme theme) =>
      (theme.titleMedium ?? textTheme.titleMedium!).copyWith(
        fontWeight: FontWeight.w700,
      );

  /// Upper shelf labels (recent searches), weekday row, micro headings.
  static TextStyle eventsMicroSectionHeading(TextTheme theme) =>
      (theme.bodySmall ?? textTheme.bodySmall!).copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w600,
      );

  static TextStyle eventsCalendarWeekdayLabel(TextTheme theme) =>
      eventsMicroSectionHeading(theme);

  /// Selected date label above agenda list.
  static TextStyle eventsCalendarSectionHeader(TextTheme theme) =>
      (theme.titleSmall ?? textTheme.titleSmall!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );

  static TextStyle eventsCalendarAgendaTitle(TextTheme theme) =>
      (theme.bodyMedium ?? textTheme.bodyMedium!).copyWith(
        fontWeight: FontWeight.w600,
      );

  /// Day cell number — pass state-specific [fontWeight] and [color].
  static TextStyle eventsCalendarDayNumber(
    TextTheme theme, {
    required FontWeight fontWeight,
    required Color color,
  }) => (theme.bodySmall ?? textTheme.bodySmall!).copyWith(
    fontWeight: fontWeight,
    color: color,
  );

  /// Empty states that should track dynamic type (feed / search).
  static TextStyle eventsEmptyStateTitle(TextTheme theme) =>
      (theme.titleMedium ?? textTheme.titleMedium!).copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  static TextStyle eventsEmptyStateSubtitle(TextTheme theme) =>
      (theme.bodyMedium ?? textTheme.bodyMedium!).copyWith(
        color: AppColors.textMuted,
        height: 1.5,
        fontWeight: FontWeight.w400,
      );

  // ---------------------------------------------------------------------------
  // Reports vertical — prefer [Theme.of] for Roboto + dynamic type.
  // ---------------------------------------------------------------------------

  /// Report detail / sheet primary title (modal chrome).
  static TextStyle reportsSheetTitle(TextTheme theme) =>
      (theme.titleMedium ?? textTheme.titleMedium!).copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      );

  /// Subtitle under the sheet title (moderation context line).
  static TextStyle reportsSheetSubtitle(TextTheme theme) =>
      (theme.bodySmall ?? textTheme.bodySmall!).copyWith(
        color: AppColors.textMuted,
        height: 1.35,
      );

  /// Section header inside report body (e.g. narrative title).
  static TextStyle reportsSectionHeader(TextTheme theme) =>
      (theme.titleSmall ?? textTheme.titleSmall!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      );

  /// Left column label in detail rows (Category, Severity, …).
  static TextStyle reportsRowLabel(TextTheme theme) =>
      (theme.bodySmall ?? textTheme.bodySmall!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
      );

  /// Right column value in detail rows.
  static TextStyle reportsRowValue(TextTheme theme) =>
      (theme.bodyMedium ?? textTheme.bodyMedium!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Emphasized numeric value (e.g. points).
  static TextStyle reportsRowValueStrong(TextTheme theme) => reportsRowValue(
    theme,
  ).copyWith(fontWeight: FontWeight.w700, color: AppColors.accentWarning);

  /// Small pill label on report cards / detail chips.
  static TextStyle reportsPillLabel(TextTheme theme) =>
      (theme.labelSmall ?? textTheme.bodySmall!).copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      );

  /// Status badge on list cards (compact).
  static TextStyle reportsBadgeLabel(TextTheme theme) =>
      (theme.labelSmall ?? textTheme.bodySmall!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );

  /// [ReportInfoBanner] title line.
  static TextStyle reportsBannerTitle(TextTheme theme) =>
      (theme.titleSmall ?? textTheme.titleSmall!).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// [ReportInfoBanner] body copy.
  static TextStyle reportsBannerBody(TextTheme theme) =>
      (theme.bodySmall ?? textTheme.bodySmall!).copyWith(
        color: AppColors.textSecondary,
        height: 1.35,
        fontWeight: FontWeight.w400,
      );

  /// Caption on evidence gallery glass pill (“Open photo”, “Tap to expand”).
  static TextStyle reportsGalleryHint(TextTheme theme) =>
      (theme.labelSmall ?? textTheme.bodySmall!).copyWith(
        fontWeight: FontWeight.w500,
        color: AppColors.textOnDark,
      );

  /// Dense `12/60`-style counters beside report form fields (Dynamic Type friendly).
  static TextStyle reportsCharCounter(TextTheme theme) =>
      (theme.labelSmall ?? textTheme.bodySmall!).copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w500,
      );

  /// Section labels in the new-report details step (category, severity, title…).
  static TextStyle reportsFormFieldLabel(TextTheme theme, {Color? color}) =>
      (theme.bodySmall ?? textTheme.bodySmall!).copyWith(
        color: color ?? AppColors.textSecondary,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      );

  /// Current severity readout above the slider track.
  static TextStyle reportsSliderValue(TextTheme theme) =>
      (theme.bodyMedium ?? textTheme.bodyMedium!).copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      );

  /// Primary CTA label on the new-report bottom bar.
  static TextStyle reportsBottomBarButtonLabel(TextTheme theme) =>
      (theme.labelLarge ?? textTheme.labelLarge!).copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      );
}
