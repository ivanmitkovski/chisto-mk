/// Injectable clock for deterministic tests (reducer, scheduler, projector).
abstract class ReportDraftClock {
  int nowMs();
}

/// Production clock backed by [DateTime.now].
class SystemReportDraftClock implements ReportDraftClock {
  const SystemReportDraftClock();

  @override
  int nowMs() => DateTime.now().millisecondsSinceEpoch;
}
