import 'package:chisto_mobile/features/reports/data/outbox/outbox_scheduler.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_entry.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:flutter_test/flutter_test.dart';

ReportOutboxEntry _entry(ReportOutboxState state) {
  return ReportOutboxEntry(
    id: 'x',
    idempotencyKey: 'k',
    draft: ReportDraft(),
    title: '',
    description: '',
    submitRequested: true,
    state: state,
    attemptCount: 0,
    createdAtMs: 1,
    updatedAtMs: 1,
  );
}

void main() {
  const OutboxScheduler s = OutboxScheduler();

  group('OutboxScheduler.afterProcess', () {
    test('continue when row null', () {
      expect(
        s.afterProcess(check: null),
        OutboxAfterProcessInstruction.continueLoop,
      );
    });

    test('continue when succeeded or failed', () {
      expect(s.afterProcess(check: _entry(ReportOutboxState.succeeded)), OutboxAfterProcessInstruction.continueLoop);
      expect(s.afterProcess(check: _entry(ReportOutboxState.failed)), OutboxAfterProcessInstruction.continueLoop);
    });

    test('break on cooldown', () {
      expect(
        s.afterProcess(check: _entry(ReportOutboxState.cooldown)),
        OutboxAfterProcessInstruction.breakOnCooldown,
      );
    });

    test('continue for pending, uploading, submitting', () {
      expect(s.afterProcess(check: _entry(ReportOutboxState.pending)), OutboxAfterProcessInstruction.continueLoop);
      expect(s.afterProcess(check: _entry(ReportOutboxState.uploading)), OutboxAfterProcessInstruction.continueLoop);
      expect(s.afterProcess(check: _entry(ReportOutboxState.submitting)), OutboxAfterProcessInstruction.continueLoop);
    });
  });

  group('OutboxScheduler.shouldStopAfterFetch', () {
    test('stops when no row', () {
      expect(s.shouldStopAfterFetch(online: true, foundRow: false), isTrue);
      expect(s.shouldStopAfterFetch(online: false, foundRow: false), isTrue);
    });

    test('stops when offline even with row', () {
      expect(s.shouldStopAfterFetch(online: false, foundRow: true), isTrue);
    });

    test('does not stop when online and row', () {
      expect(s.shouldStopAfterFetch(online: true, foundRow: true), isFalse);
    });
  });
}
