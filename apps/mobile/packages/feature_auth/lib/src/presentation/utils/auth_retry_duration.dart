import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_reports/feature_reports.dart';

/// Formats [retryAfterSeconds] from auth API errors for user-facing copy.
String formatAuthRetryDuration(AppLocalizations l10n, int? retryAfterSeconds) =>
    formatReportCapacityRetryDuration(l10n, retryAfterSeconds);
