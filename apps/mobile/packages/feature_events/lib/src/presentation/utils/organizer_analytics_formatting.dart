import 'package:chisto_core/chisto_core.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';

const RelativeTimeFormatter _analyticsRelativeTimeFormatter =
    RelativeTimeFormatter(RelativeTimeFormatOptions.analytics);

/// Short relative time for analytics “updated / last activity” captions.
String formatAnalyticsRelativeTime(
  AppLocalizations l10n,
  DateTime instant,
  DateTime now,
) {
  return _analyticsRelativeTimeFormatter.format(
    _AnalyticsRelativeTimeLabels(l10n),
    instant,
    now,
  );
}

class _AnalyticsRelativeTimeLabels implements RelativeTimeLabels {
  _AnalyticsRelativeTimeLabels(this.l10n);

  final AppLocalizations l10n;

  @override
  String get justNow => l10n.eventsAnalyticsRelativeJustNow;

  @override
  String minutes(int count) => l10n.eventsAnalyticsRelativeMinutesAgo(count);

  @override
  String hours(int count) => l10n.eventsAnalyticsRelativeHoursAgo(count);

  @override
  String days(int count) => l10n.eventsAnalyticsRelativeDaysAgo(count);

  @override
  String weeks(int count) => l10n.eventsAnalyticsRelativeWeeksAgo(count);

  @override
  String shortCalendarDate(DateTime local) => weeks(1);

  @override
  String longCalendarDate(DateTime local) => weeks(1);
}
