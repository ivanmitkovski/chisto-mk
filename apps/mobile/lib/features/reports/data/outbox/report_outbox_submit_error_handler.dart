import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_entry.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_error_classifier.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_repository.dart';

/// Persists submit-phase failures: terminal, server cooldown, or bounded retry backoff.
class ReportOutboxSubmitErrorHandler {
  ReportOutboxSubmitErrorHandler({
    required ReportOutboxRepository repository,
    required void Function(ReportOutboxEntry?) emitActiveEntry,
    required int maxAttempts,
  }) : _repo = repository,
       _emitActiveEntry = emitActiveEntry,
       _maxAttempts = maxAttempts;

  final ReportOutboxRepository _repo;
  final void Function(ReportOutboxEntry?) _emitActiveEntry;
  final int _maxAttempts;

  Future<void> handle(ReportOutboxEntry entry, AppError err) async {
    final ReportOutboxErrorKind kind = classifyReportSubmitError(err);
    final int nextAttempt = entry.attemptCount + 1;
    switch (kind) {
      case ReportOutboxErrorKind.terminal:
        await _repo.update(
          entry.copyWith(
            state: ReportOutboxState.failed,
            attemptCount: nextAttempt,
            lastErrorCode: err.code,
            lastErrorMessage: err.message,
          ),
        );
        _emitActiveEntry(await _repo.getById(entry.id));
      case ReportOutboxErrorKind.cooldown:
        final int? until = cooldownUntilMsFromAppError(err);
        await _repo.update(
          entry.copyWith(
            state: ReportOutboxState.cooldown,
            attemptCount: nextAttempt,
            lastErrorCode: err.code,
            lastErrorMessage: err.message,
            cooldownUntilMs: until,
          ),
        );
        _emitActiveEntry(await _repo.getById(entry.id));
      case ReportOutboxErrorKind.retryable:
        if (nextAttempt >= _maxAttempts) {
          await _repo.update(
            entry.copyWith(
              state: ReportOutboxState.failed,
              attemptCount: nextAttempt,
              lastErrorCode: err.code,
              lastErrorMessage: err.message,
            ),
          );
          _emitActiveEntry(await _repo.getById(entry.id));
        } else {
          final int until =
              DateTime.now().millisecondsSinceEpoch + backoffMsForAttempt(nextAttempt);
          await _repo.update(
            entry.copyWith(
              state: ReportOutboxState.cooldown,
              attemptCount: nextAttempt,
              lastErrorCode: err.code,
              lastErrorMessage: err.message,
              cooldownUntilMs: until,
            ),
          );
          _emitActiveEntry(await _repo.getById(entry.id));
        }
    }
  }
}
