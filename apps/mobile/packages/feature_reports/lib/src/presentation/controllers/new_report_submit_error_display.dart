import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:flutter/foundation.dart';

/// User-facing submit error normalization shared by the wizard controller and
/// [NewReportSubmitUiFlow].
abstract final class NewReportSubmitErrorDisplay {
  /// Maps opaque UNKNOWN/validation echoes to [SUBMIT_FAILED_RETRYABLE] so UI
  /// resolves copy via [localizedAppErrorMessage].
  static AppError humanizeSubmitErrorForBanner(AppError e) {
    final bool isUnknown = e.code == 'UNKNOWN';
    final bool isUnknownEchoedByValidation =
        e.code == 'VALIDATION_ERROR' && e.details == 'UNKNOWN';
    if (!isUnknown && !isUnknownEchoedByValidation) {
      return e;
    }
    return AppError(
      code: 'SUBMIT_FAILED_RETRYABLE',
      message: '',
      retryable: true,
      cause: e.cause,
      details: kDebugMode ? (e.details ?? e.cause?.toString()) : e.details,
    );
  }
}
