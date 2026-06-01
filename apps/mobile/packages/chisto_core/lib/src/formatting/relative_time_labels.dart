/// Locale-specific strings for [RelativeTimeFormatter] (wire to `AppLocalizations`).
abstract class RelativeTimeLabels {
  String get justNow;
  String minutes(int count);
  String hours(int count);
  String days(int count);

  /// Used when [RelativeTimeFormatOptions.includeWeeksAfterDays] is true.
  String weeks(int count);

  /// Short calendar label (e.g. `dd.MM`) when the instant is older than the relative window.
  String shortCalendarDate(DateTime local);

  /// Longer date label (e.g. `yMMMd`) for comment meta and similar.
  String longCalendarDate(DateTime local);
}
