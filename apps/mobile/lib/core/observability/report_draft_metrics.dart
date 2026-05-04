/// Lightweight counters for report draft persistence (tests / local diagnostics).
class ReportDraftMetrics {
  ReportDraftMetrics._();

  static final ReportDraftMetrics instance = ReportDraftMetrics._();

  int persistSuccessCount = 0;

  void recordPersistSuccess() => persistSuccessCount++;

  void resetForTest() {
    persistSuccessCount = 0;
  }
}
