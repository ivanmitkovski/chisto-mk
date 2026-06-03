import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:flutter/foundation.dart';

/// User-facing submit error copy and UNKNOWN de-masking shared by the wizard
/// controller and [NewReportSubmitUiFlow].
abstract final class NewReportSubmitErrorDisplay {
  static const String genericSubmitFailureMessage =
      "Couldn't submit. Check your connection and try again.";

  /// Surfaces a retryable banner with the real transport/server message when
  /// available; only falls back to [genericSubmitFailureMessage] when there is
  /// no actionable detail.
  static AppError humanizeSubmitErrorForBanner(AppError e) {
    final bool isUnknown = e.code == 'UNKNOWN';
    final bool isUnknownEchoedByValidation =
        e.code == 'VALIDATION_ERROR' &&
        (e.details == 'UNKNOWN' || e.message == 'An unexpected error occurred.');
    if (!isUnknown && !isUnknownEchoedByValidation) {
      return e;
    }
    final String? actionable = _extractActionableMessage(e);
    if (actionable != null && actionable.isNotEmpty) {
      return AppError(
        code: 'SUBMIT_FAILED_RETRYABLE',
        message: actionable,
        retryable: true,
        cause: e.cause,
        details: kDebugMode
            ? (e.details ?? e.cause?.toString())
            : e.details,
      );
    }
    return const AppError(
      code: 'SUBMIT_FAILED_RETRYABLE',
      message: genericSubmitFailureMessage,
      retryable: true,
    );
  }

  static String? _extractActionableMessage(AppError e) {
    if (e.message.isNotEmpty &&
        e.message != 'An unexpected error occurred.') {
      return e.message;
    }
    final Object? cause = e.cause;
    if (cause is AppError && cause.message.isNotEmpty) {
      return cause.message;
    }
    if (cause != null) {
      final String raw = cause.toString();
      if (raw.isNotEmpty && raw != 'Exception') {
        return raw;
      }
    }
    if (e.details is String) {
      final String d = e.details! as String;
      if (d.isNotEmpty && d != 'UNKNOWN') {
        return d;
      }
    }
    return null;
  }
}
