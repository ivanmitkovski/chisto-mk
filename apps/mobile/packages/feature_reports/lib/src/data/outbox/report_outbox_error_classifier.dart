import 'package:chisto_infrastructure/core/errors/app_error.dart';

/// Maps [AppError] to outbox handling (terminal vs cooldown vs retry).
enum ReportOutboxErrorKind { terminal, cooldown, retryable }

ReportOutboxErrorKind classifyReportSubmitError(AppError e) {
  if (e.code == 'REPORTING_COOLDOWN' || e.code == 'DUPLICATE_SUBMIT_INFLIGHT') {
    return ReportOutboxErrorKind.cooldown;
  }
  if (e.retryable && e.code == 'CONFLICT') {
    return ReportOutboxErrorKind.cooldown;
  }
  if (e.retryable ||
      e.code == 'NETWORK_ERROR' ||
      e.code == 'TIMEOUT' ||
      e.code == 'SERVER_ERROR' ||
      e.code == 'TOO_MANY_REQUESTS') {
    return ReportOutboxErrorKind.retryable;
  }
  // A bare `UNKNOWN` (empty/non-JSON 2xx body, platform cleartext block, or
  // a non-AppError thrown deep in submit) almost always reflects a transient
  // transport problem rather than a server-rejected payload. Retry with the
  // **same** idempotency key so the user does not burn a slot on noise.
  if (e.code == 'UNKNOWN') {
    return ReportOutboxErrorKind.retryable;
  }
  return ReportOutboxErrorKind.terminal;
}

int? cooldownUntilMsFromAppError(AppError e) {
  final bool usesRetryAfter =
      e.code == 'REPORTING_COOLDOWN' ||
      e.code == 'DUPLICATE_SUBMIT_INFLIGHT' ||
      (e.retryable && e.code == 'CONFLICT');
  if (!usesRetryAfter) {
    return null;
  }
  final dynamic d = e.details;
  if (d is! Map<String, dynamic>) {
    return DateTime.now().millisecondsSinceEpoch +
        (e.code == 'DUPLICATE_SUBMIT_INFLIGHT' ? 5 : 60) * 1000;
  }
  final int? sec = (d['retryAfterSeconds'] as num?)?.toInt();
  if (sec != null && sec > 0) {
    return DateTime.now().millisecondsSinceEpoch + sec * 1000;
  }
  final String? nextAtStr = (d['nextEmergencyReportAvailableAt'] as String?)
      ?.trim();
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
  const int cap = 5 * 60 * 1000;
  final int ms = base > cap ? cap : base;
  final int jitter = (ms * 0.15).round();
  return ms +
      (DateTime.now().microsecondsSinceEpoch % (jitter * 2 + 1)) -
      jitter;
}
