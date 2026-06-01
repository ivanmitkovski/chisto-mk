/// Tunables for [RelativeTimeFormatter] presets.
class RelativeTimeFormatOptions {
  const RelativeTimeFormatOptions({
    this.compareInstantAsUtc = false,
    this.clampFutureToNow = true,
    this.treatSubMinuteAsJustNow = true,
    this.clampBucketCounts = false,
    this.includeWeeksAfterDays = false,
    this.absoluteAfterDays = 7,
    this.useLongCalendarDate = false,
    this.useShortCalendarDate = false,
  });

  /// Diff uses `now.difference(instant.toUtc())` when true (analytics).
  final bool compareInstantAsUtc;

  /// Future instants are treated as [RelativeTimeLabels.justNow] when true.
  final bool clampFutureToNow;

  /// Sub-minute deltas map to [RelativeTimeLabels.justNow] when true.
  final bool treatSubMinuteAsJustNow;

  /// Clamps minute/hour/day counts to 1..59 / 1..23 / 1..6 style buckets.
  final bool clampBucketCounts;

  /// After 7 days, emit [RelativeTimeLabels.weeks] instead of calendar date.
  final bool includeWeeksAfterDays;

  /// Days threshold before switching to calendar (or weeks) output.
  final int absoluteAfterDays;

  /// Uses [RelativeTimeLabels.longCalendarDate] past the relative window.
  final bool useLongCalendarDate;

  /// Uses [RelativeTimeLabels.shortCalendarDate] past the relative window.
  final bool useShortCalendarDate;

  /// Notifications inbox / tiles (`dd.MM` after 7 days).
  static const RelativeTimeFormatOptions notifications =
      RelativeTimeFormatOptions(useShortCalendarDate: true);

  /// Organizer analytics captions (weeks after 7 days, UTC diff).
  static const RelativeTimeFormatOptions analytics = RelativeTimeFormatOptions(
    compareInstantAsUtc: true,
    clampBucketCounts: true,
    includeWeeksAfterDays: true,
  );

  /// Site history list (medium date after 7 days).
  static const RelativeTimeFormatOptions siteHistory =
      RelativeTimeFormatOptions(useLongCalendarDate: true);

  /// Comment meta subtitles (long date after 7 days, clamp minutes/hours/days).
  static const RelativeTimeFormatOptions commentMeta =
      RelativeTimeFormatOptions(
        clampBucketCounts: true,
        useLongCalendarDate: true,
      );
}
