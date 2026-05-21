import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_capacity_retry_duration.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

/// Formats [retryAfterSeconds] from auth API errors for user-facing copy.
String formatAuthRetryDuration(AppLocalizations l10n, int? retryAfterSeconds) =>
    formatReportCapacityRetryDuration(l10n, retryAfterSeconds);
