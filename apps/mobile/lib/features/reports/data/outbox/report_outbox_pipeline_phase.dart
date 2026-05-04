/// High-level outbox coordinator phase for UI / analytics (no PII).
enum ReportOutboxPipelinePhase {
  idle,
  active,
  offlineWait,
  cooldownWait,
}
