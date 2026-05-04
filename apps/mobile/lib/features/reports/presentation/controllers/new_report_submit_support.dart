import 'package:chisto_mobile/features/reports/domain/draft/report_idempotency_key.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';

/// Idempotency key generation and error-shape parsing for report submission.
class NewReportSubmitSupport {
  const NewReportSubmitSupport._();

  static String newIdempotencyKey() => ReportIdempotencyKey.generate();

  static ReportCapacity? capacityFromErrorDetails(
    dynamic details, {
    required String defaultUnlockHint,
  }) {
    if (details is! Map<String, dynamic>) return null;
    final int creditsAvailable =
        (details['creditsAvailable'] as num?)?.toInt() ?? 0;
    final bool emergencyAvailable =
        details['emergencyAvailable'] as bool? ?? false;
    final int? retryAfterSeconds = (details['retryAfterSeconds'] as num?)
        ?.toInt();
    final String unlockHint =
        details['unlockHint'] as String? ?? defaultUnlockHint;
    final String? nextAtStr =
        (details['nextEmergencyReportAvailableAt'] as String?)?.trim();
    return ReportCapacity(
      creditsAvailable: creditsAvailable,
      emergencyAvailable: emergencyAvailable,
      emergencyWindowDays: 7,
      retryAfterSeconds: retryAfterSeconds,
      nextEmergencyReportAvailableAt: nextAtStr != null && nextAtStr.isNotEmpty
          ? DateTime.tryParse(nextAtStr)?.toUtc()
          : null,
      nextRefillAtMs: (details['nextRefillAtMs'] as num?)?.toInt(),
      unlockHint: unlockHint,
    );
  }
}
