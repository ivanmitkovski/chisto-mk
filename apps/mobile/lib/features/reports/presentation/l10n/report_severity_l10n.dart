import 'package:chisto_mobile/l10n/app_localizations.dart';

/// Localized severity label for report UI (1–5 scale).
String reportSeverityDisplayLabel(AppLocalizations l10n, int value) {
  final int v = value.clamp(1, 5);
  final String tier = switch (v) {
    1 => l10n.reportSeverityLow,
    2 => l10n.reportSeverityModerate,
    3 => l10n.reportSeveritySignificant,
    4 => l10n.reportSeverityHigh,
    _ => l10n.reportSeverityCritical,
  };
  return '$v — $tier';
}
