/// Tunables for [ReportOutboxCoordinator] and submit/upload phases.
class OutboxConfig {
  const OutboxConfig({
    this.maxSubmitAttempts = 6,
    this.uploadAutoRetries = 3,
    this.submitAwaitTimeout = const Duration(minutes: 5),
  });

  final int maxSubmitAttempts;
  final int uploadAutoRetries;
  final Duration submitAwaitTimeout;

  static const OutboxConfig defaults = OutboxConfig();
}
