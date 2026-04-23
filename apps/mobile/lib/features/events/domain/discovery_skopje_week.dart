import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

bool _tzDataLoaded = false;

void _ensureTimeZones() {
  if (_tzDataLoaded) {
    return;
  }
  tzdata.initializeTimeZones();
  _tzDataLoaded = true;
}

/// Inclusive calendar bounds (Monday–Sunday) in **Europe/Skopje** for the ISO week
/// that contains [referenceUtc].
///
/// Used for discovery "this week" list queries (`dateFrom` / `dateTo` as `YYYY-MM-DD`).
/// Matches product convention: week boundaries follow Skopje wall calendar, not the device locale.
({DateTime dateFrom, DateTime dateTo}) skopjeCalendarWeekBoundsInclusive(
  DateTime referenceUtc,
) {
  _ensureTimeZones();
  final tz.Location skopje = tz.getLocation('Europe/Skopje');
  final tz.TZDateTime now = tz.TZDateTime.from(referenceUtc.toUtc(), skopje);
  final int daysSinceMonday = now.weekday - 1; // Dart: Mon = 1 … Sun = 7
  final tz.TZDateTime mondayMidnight = tz.TZDateTime(
    skopje,
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: daysSinceMonday));
  final tz.TZDateTime sunday = mondayMidnight.add(const Duration(days: 6));
  final DateTime dateFrom = DateTime.utc(mondayMidnight.year, mondayMidnight.month, mondayMidnight.day);
  final DateTime dateTo = DateTime.utc(sunday.year, sunday.month, sunday.day);
  return (dateFrom: dateFrom, dateTo: dateTo);
}
