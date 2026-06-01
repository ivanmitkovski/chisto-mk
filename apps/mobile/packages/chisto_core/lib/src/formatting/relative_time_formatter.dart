import 'package:chisto_core/src/formatting/relative_time_format_options.dart';
import 'package:chisto_core/src/formatting/relative_time_labels.dart';

/// Shared relative-time bucketing for notifications, comments, analytics, and history.
class RelativeTimeFormatter {
  const RelativeTimeFormatter([
    this.options = const RelativeTimeFormatOptions(),
  ]);

  final RelativeTimeFormatOptions options;

  String format(RelativeTimeLabels labels, DateTime instant, DateTime now) {
    final DateTime effectiveInstant =
        options.clampFutureToNow && instant.isAfter(now) ? now : instant;
    final Duration diff = options.compareInstantAsUtc
        ? now.difference(effectiveInstant.toUtc())
        : now.difference(effectiveInstant);

    if (options.clampFutureToNow && diff.isNegative) {
      return labels.justNow;
    }
    if (options.treatSubMinuteAsJustNow && diff.inMinutes < 1) {
      return labels.justNow;
    }
    if (diff.inHours < 1) {
      final int m = options.clampBucketCounts
          ? diff.inMinutes.clamp(1, 59)
          : diff.inMinutes;
      return labels.minutes(m);
    }
    if (diff.inHours < 24) {
      final int h = options.clampBucketCounts
          ? diff.inHours.clamp(1, 23)
          : diff.inHours;
      return labels.hours(h);
    }
    if (diff.inDays < options.absoluteAfterDays) {
      final int maxDay = options.absoluteAfterDays - 1;
      final int d = options.clampBucketCounts
          ? diff.inDays.clamp(1, maxDay)
          : diff.inDays;
      return labels.days(d);
    }
    if (options.includeWeeksAfterDays) {
      return labels.weeks((diff.inDays / 7).floor().clamp(1, 52));
    }
    final DateTime local = effectiveInstant.toLocal();
    if (options.useLongCalendarDate) {
      return labels.longCalendarDate(local);
    }
    if (options.useShortCalendarDate) {
      return labels.shortCalendarDate(local);
    }
    return labels.longCalendarDate(local);
  }
}
