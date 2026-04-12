import 'package:chisto_mobile/l10n/app_localizations.dart';

/// Short user-facing summary of an RFC 5545 [rrule] fragment (e.g. `FREQ=WEEKLY`).
String? summarizeRecurrenceRule(String? rrule, AppLocalizations l10n) {
  if (rrule == null) {
    return null;
  }
  String norm = rrule.trim().toUpperCase();
  if (norm.isEmpty) {
    return null;
  }
  if (norm.startsWith('RRULE:')) {
    norm = norm.substring(6);
  }
  final Map<String, String> parts = <String, String>{};
  for (final String part in norm.split(';')) {
    final int eq = part.indexOf('=');
    if (eq <= 0) {
      continue;
    }
    parts[part.substring(0, eq)] = part.substring(eq + 1);
  }
  final String? freq = parts['FREQ'];
  final int interval = int.tryParse(parts['INTERVAL'] ?? '1') ?? 1;
  switch (freq) {
    case 'DAILY':
      return l10n.eventsRecurrenceDaily;
    case 'WEEKLY':
      if (interval >= 2) {
        return l10n.eventsRecurrenceBiweekly;
      }
      return l10n.eventsRecurrenceWeekly;
    case 'MONTHLY':
      return l10n.eventsRecurrenceMonthly;
    default:
      return null;
  }
}
