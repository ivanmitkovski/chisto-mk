import 'package:chisto_mobile/l10n/app_localizations.dart';

/// Formats retry-after duration for cooldown copy (days, hours, minutes, seconds).
String formatReportCapacityRetryDuration(
  AppLocalizations l10n,
  int? retryAfterSeconds,
) {
  if (retryAfterSeconds == null || retryAfterSeconds <= 0) {
    return l10n.reportCooldownRetrySoon;
  }
  final int days = retryAfterSeconds ~/ 86400;
  int remainder = retryAfterSeconds % 86400;
  final int hours = remainder ~/ 3600;
  remainder = remainder % 3600;
  final int minutes = remainder ~/ 60;
  final int seconds = remainder % 60;

  final String sep = l10n.reportCooldownDurationListSeparator;

  if (days > 0) {
    final List<String> parts = <String>[l10n.reportCooldownDurationDays(days)];
    if (hours > 0) {
      parts.add(l10n.reportCooldownDurationHours(hours));
    }
    if (minutes > 0) {
      parts.add(l10n.reportCooldownDurationMinutes(minutes));
    } else if (hours == 0 && seconds > 0) {
      parts.add(l10n.reportCooldownDurationSeconds(seconds));
    }
    return parts.join(sep);
  }
  if (hours > 0) {
    final List<String> parts = <String>[
      l10n.reportCooldownDurationHours(hours),
    ];
    if (minutes > 0) {
      parts.add(l10n.reportCooldownDurationMinutes(minutes));
    } else if (seconds > 0) {
      parts.add(l10n.reportCooldownDurationSeconds(seconds));
    }
    return parts.join(sep);
  }
  if (minutes > 0) {
    if (seconds > 0) {
      return l10n.reportCooldownDurationMinutes(minutes) +
          sep +
          l10n.reportCooldownDurationSeconds(seconds);
    }
    return l10n.reportCooldownDurationMinutes(minutes);
  }
  return l10n.reportCooldownDurationSeconds(seconds);
}
