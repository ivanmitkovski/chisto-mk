import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_entry.dart'
    show ReportOutboxEntry, ReportOutboxState;

/// Instruction for the coordinator drain loop after one process pass.
enum OutboxAfterProcessInstruction {
  /// Fetch the next processable row.
  continueLoop,

  /// Stop spinning until connectivity or cooldown timer fires; UI shows row.
  breakOnCooldown,
}

/// Pure navigation for the outbox drain loop (connectivity + row state).
class OutboxScheduler {
  const OutboxScheduler();

  OutboxAfterProcessInstruction afterProcess({
    required ReportOutboxEntry? check,
  }) {
    if (check == null ||
        check.state == ReportOutboxState.succeeded ||
        check.state == ReportOutboxState.failed) {
      return OutboxAfterProcessInstruction.continueLoop;
    }
    if (check.state == ReportOutboxState.cooldown) {
      return OutboxAfterProcessInstruction.breakOnCooldown;
    }
    return OutboxAfterProcessInstruction.continueLoop;
  }

  bool shouldStopAfterFetch({required bool online, required bool foundRow}) {
    if (!foundRow) {
      return true;
    }
    return !online;
  }
}
