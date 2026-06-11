import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Localized relative day label for a report timestamp shown on list cards
/// (e.g. "Today", "Yesterday", "3 days ago", "2 weeks ago", "6/9/2026").
///
/// Uses the **calendar-day** difference rather than elapsed 24h periods, so a
/// report submitted yesterday never renders as "Today" just because fewer than
/// 24 hours have passed. The comparison runs in the timestamp's own zone (UTC
/// for API values) so the label stays consistent with the absolute date shown
/// on the report detail sheet.
///
/// [now] is injectable for deterministic tests.
String reportRelativeDateLabel(
  AppLocalizations l10n,
  DateTime date, {
  required String locale,
  DateTime? now,
}) {
  final DateTime reference = now ?? DateTime.now();
  // Align the reference clock to the timestamp's zone. API timestamps are UTC,
  // and the detail sheet formats them with their own (UTC) fields; matching
  // that here guarantees the list and detail never disagree on the day.
  final DateTime alignedNow = date.isUtc
      ? reference.toUtc()
      : reference.toLocal();
  final int days = _calendarDaysBetween(from: date, to: alignedNow);

  if (days <= 0) return l10n.eventsDateRelativeToday;
  if (days == 1) return l10n.profilePointsHistoryDayYesterday;
  if (days < 7) return l10n.eventsDateRelativeDaysAgo(days);
  if (days < 30) return l10n.reportListDateWeeksAgo((days / 7).floor());
  return DateFormat.yMd(locale).format(date);
}

/// Whole calendar days between [from] and [to] using each value's own Y/M/D.
///
/// Normalizes both to UTC midnight (UTC has no DST) so a 23h/25h DST day never
/// shifts the count by one.
int _calendarDaysBetween({required DateTime from, required DateTime to}) {
  final DateTime a = DateTime.utc(from.year, from.month, from.day);
  final DateTime b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}
