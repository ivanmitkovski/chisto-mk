/// Stable id for the single in-progress wizard draft row (not yet submitted).
const String kReportWizardDraftRowId = 'local_report_draft_v1';

/// Upper bound for SQLite + photo hydration when opening the wizard.
const Duration kReportDraftLoadTimeout = Duration(seconds: 10);

/// Alias for draft restore budget (telemetry compares against actuals).
const Duration kReportDraftRestoreBudget = kReportDraftLoadTimeout;

/// Soft wall-clock budget per photo for JPEG normalization before upload (not a hard kill).
const Duration kReportUploadPrepBudgetPerPhotoSoft = Duration(seconds: 45);

/// Soft cap for one coordinator drain invocation (excluding OS throttling).
const Duration kReportOutboxCoordinatorDrainSoftCap = Duration(minutes: 8);
