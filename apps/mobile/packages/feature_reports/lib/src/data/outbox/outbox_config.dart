/// Tunables for [ReportOutboxCoordinator] and submit/upload phases.
class OutboxConfig {
  const OutboxConfig({
    this.maxSubmitAttempts = 6,
    this.uploadAutoRetries = 3,
    this.submitAwaitTimeout = const Duration(minutes: 5),
    this.processingLeaseDuration = const Duration(minutes: 3),
  });

  final int maxSubmitAttempts;
  final int uploadAutoRetries;
  final Duration submitAwaitTimeout;

  /// Cross-isolate lock on an outbox row while upload/submit runs.
  final Duration processingLeaseDuration;

  static const OutboxConfig defaults = OutboxConfig();
}
