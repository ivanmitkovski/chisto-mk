class ReportCapacity {
  const ReportCapacity({
    required this.creditsAvailable,
    required this.emergencyAvailable,
    required this.emergencyWindowDays,
    required this.retryAfterSeconds,
    required this.nextEmergencyReportAvailableAt,
    this.nextRefillAtMs,
    required this.unlockHint,
  });

  final int creditsAvailable;
  final bool emergencyAvailable;
  final int emergencyWindowDays;
  final int? retryAfterSeconds;

  /// UTC instant from API when emergency reporting unlocks; null if not on cooldown.
  final DateTime? nextEmergencyReportAvailableAt;

  /// Epoch ms when emergency allowance refills (from API); null when not applicable.
  final int? nextRefillAtMs;

  final String unlockHint;
}
