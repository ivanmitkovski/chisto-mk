import 'package:chisto_core/src/errors/app_error.dart';
import 'package:chisto_core/src/outbox/outbox_backoff_scheduler.dart';

/// Result of flushing a single outbox row.
enum OutboxFlushDisposition { completed, retryableSkipped, terminalRemoved }

/// Shared drain loop: one bad retryable row must not block the rest of the queue.
abstract class OutboxCoordinatorBase<TEntry> {
  OutboxCoordinatorBase({OutboxBackoffScheduler? backoff})
    : backoff = backoff ?? OutboxBackoffScheduler(onRetry: () {});

  final OutboxBackoffScheduler backoff;

  /// Peek pending rows in stable order.
  Future<List<TEntry>> peekPending();

  /// Attempt to sync one row; return how the coordinator should treat it.
  Future<OutboxFlushDisposition> flushEntry(TEntry entry);

  /// Drains [peekPending] until empty or only retryable skips remain.
  Future<void> drainPending() async {
    final List<TEntry> pending = await peekPending();
    var hadRetryableSkip = false;
    for (final TEntry entry in pending) {
      try {
        final OutboxFlushDisposition d = await flushEntry(entry);
        if (d == OutboxFlushDisposition.retryableSkipped) {
          hadRetryableSkip = true;
        }
      } on AppError catch (err) {
        if (err.retryable) {
          hadRetryableSkip = true;
          continue;
        }
      } catch (_) {
        hadRetryableSkip = true;
        continue;
      }
    }
    if (hadRetryableSkip) {
      backoff.scheduleRetry();
    } else {
      backoff.reset();
    }
  }
}
