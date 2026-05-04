import 'package:chisto_mobile/l10n/app_localizations.dart';

/// Short relative label for the wizard autosave indicator.
String reportDraftSavedIndicator(AppLocalizations l10n, int? lastMs) {
  if (lastMs == null) {
    return '';
  }
  final Duration ago = DateTime.now().difference(
    DateTime.fromMillisecondsSinceEpoch(lastMs),
  );
  if (ago.inSeconds < 45) {
    return l10n.reportDraftSavedJustNow;
  }
  if (ago.inMinutes < 60) {
    final int minutes = ago.inMinutes < 1 ? 1 : ago.inMinutes;
    return l10n.reportDraftSavedMinutesAgo(minutes);
  }
  final int hours = ago.inHours < 1 ? 1 : ago.inHours;
  return l10n.reportDraftSavedHoursAgo(hours);
}
