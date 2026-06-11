import 'package:chisto_infrastructure/l10n/app_localizations.dart';

/// Resolves a civic actor label for UI (reporter, organizer, comment author, etc.).
String civicActorDisplayLabel(
  AppLocalizations l10n, {
  required String? displayName,
  required bool isDeleted,
  String anonymousFallback = 'Anonymous',
}) {
  if (isDeleted) {
    return l10n.deletedUser;
  }
  final String trimmed = displayName?.trim() ?? '';
  if (trimmed.isEmpty) {
    return anonymousFallback;
  }
  return trimmed;
}
