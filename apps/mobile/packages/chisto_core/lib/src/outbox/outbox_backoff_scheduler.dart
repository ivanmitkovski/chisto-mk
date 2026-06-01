import 'dart:async';
import 'dart:math' as math;

/// Exponential backoff timer shared by engagement/report/chat outbox coordinators.
class OutboxBackoffScheduler {
  OutboxBackoffScheduler({
    this.initialDelayMs = 2000,
    this.maxDelayMs = 60000,
    required void Function() onRetry,
  }) : _onRetry = onRetry;

  final int initialDelayMs;
  final int maxDelayMs;
  final void Function() _onRetry;

  Timer? _timer;
  int _delayMs = 2000;

  void scheduleRetry() {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: _delayMs), () {
      _delayMs = math.min(_delayMs * 2, maxDelayMs);
      _onRetry();
    });
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _delayMs = initialDelayMs;
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _delayMs = initialDelayMs;
  }
}

/// Chat outbox per-entry retry delay (exponential, capped at 30s).
Duration chatOutboxRetryDelayAfterAttempt(int attemptCount) {
  final int capped = math.min(attemptCount, 8);
  final int ms = math.min(30000, 200 * (1 << capped));
  return Duration(milliseconds: ms < 200 ? 200 : ms);
}
