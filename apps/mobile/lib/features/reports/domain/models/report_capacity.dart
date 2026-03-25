class ReportCapacity {
  const ReportCapacity({
    required this.creditsAvailable,
    required this.emergencyAvailable,
    required this.emergencyWindowDays,
    required this.retryAfterSeconds,
    required this.unlockHint,
  });

  final int creditsAvailable;
  final bool emergencyAvailable;
  final int emergencyWindowDays;
  final int? retryAfterSeconds;
  final String unlockHint;
}

