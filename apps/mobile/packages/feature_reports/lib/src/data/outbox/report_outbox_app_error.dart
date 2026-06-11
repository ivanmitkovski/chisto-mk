import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_entry.dart';

/// Maps persisted outbox failure codes to localized [AppError] instances.
AppError appErrorFromOutboxFailure(ReportOutboxEntry entry) {
  final String code = entry.lastErrorCode ?? 'UNKNOWN';
  switch (code) {
    case 'NETWORK_ERROR':
      return AppError.network();
    case 'TIMEOUT':
      return AppError.timeout();
    case 'SERVER_ERROR':
    case 'INTERNAL_ERROR':
    case 'DATABASE_UNAVAILABLE':
    case 'DATABASE_TIMEOUT':
      return AppError.server();
    case 'TOO_MANY_REQUESTS':
      return AppError.tooManyRequests();
    case 'VALIDATION_ERROR':
    case 'BAD_REQUEST':
      return AppError.validation(message: '', details: code);
    default:
      return AppError(code: code, message: '', retryable: false);
  }
}
