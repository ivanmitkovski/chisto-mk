import 'package:chisto_mobile/core/errors/app_error.dart';

/// Maps [AppError] to outbox handling (terminal vs cooldown vs retry).
enum ReportOutboxErrorKind {
  terminal,
  cooldown,
  retryable,
}

ReportOutboxErrorKind classifyReportSubmitError(AppError e) {
  if (e.code == 'REPORTING_COOLDOWN') {
    return ReportOutboxErrorKind.cooldown;
  }
  if (e.retryable ||
      e.code == 'NETWORK_ERROR' ||
      e.code == 'TIMEOUT' ||
      e.code == 'SERVER_ERROR' ||
      e.code == 'TOO_MANY_REQUESTS') {
    return ReportOutboxErrorKind.retryable;
  }
  return ReportOutboxErrorKind.terminal;
}

int? cooldownUntilMsFromAppError(AppError e) {
  if (e.code != 'REPORTING_COOLDOWN') {
    return null;
  }
  final dynamic d = e.details;
  if (d is! Map<String, dynamic>) {
    return DateTime.now().millisecondsSinceEpoch + 60 * 1000;
  }
  final int? sec = (d['retryAfterSeconds'] as num?)?.toInt();
  if (sec != null && sec > 0) {
    return DateTime.now().millisecondsSinceEpoch + sec * 1000;
  }
  final String? nextAtStr = (d['nextEmergencyReportAvailableAt'] as String?)?.trim();
  if (nextAtStr != null && nextAtStr.isNotEmpty) {
    final DateTime? t = DateTime.tryParse(nextAtStr)?.toUtc();
    if (t != null) {
      return t.millisecondsSinceEpoch;
    }
  }
  return DateTime.now().millisecondsSinceEpoch + 60 * 1000;
}

int backoffMsForAttempt(int attempt) {
  final int capped = attempt.clamp(1, 8);
  final int base = 2000 * (1 << (capped - 1));
  final int cap = 5 * 60 * 1000;
  final int ms = base > cap ? cap : base;
  final int jitter = (ms * 0.15).round();
  return ms +
      (DateTime.now().microsecondsSinceEpoch % (jitter * 2 + 1)) -
      jitter;
}
