import 'package:feature_reports/src/data/outbox/report_outbox_entry.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/domain/models/report_draft_summary.dart';
import 'package:feature_reports/src/domain/models/report_wizard_restore_snapshot.dart';

ReportWizardRestoreSnapshot reportWizardRestoreSnapshotOf(
  ReportOutboxEntry row,
) {
  return ReportWizardRestoreSnapshot(
    draft: row.draft,
    title: row.title,
    description: row.description,
    currentStageName: row.currentStageName,
    attemptedStageNames: List<String>.from(row.attemptedStageNames),
    lastPersistedAtMs: row.lastPersistedAtMs,
    updatedAtMs: row.updatedAtMs,
  );
}

/// Wizard row finished submit successfully — must not resume or autosave over.
bool isReportWizardDraftTerminalSubmit(ReportOutboxEntry row) {
  if (row.state == ReportOutboxState.succeeded) {
    return true;
  }
  final String? id = row.reportId;
  return id != null && id.isNotEmpty;
}

/// True if the SQLite wizard row should drive resume UI / block SP import, etc.
bool isReportWizardDraftEntryResumable(ReportOutboxEntry row) {
  if (isReportWizardDraftTerminalSubmit(row)) {
    return false;
  }
  return reportWizardRestoreSnapshotOf(row).isResumableWizardBody;
}

/// Pure projection of [ReportDraftSummary] from a wizard row (no IO).
class ReportDraftSummaryProjector {
  const ReportDraftSummaryProjector._();

  static ReportDraftSummary fromWizardRow(ReportOutboxEntry? row) {
    if (row == null) {
      return ReportDraftSummary.empty;
    }
    if (!isReportWizardDraftEntryResumable(row)) {
      return ReportDraftSummary.empty;
    }
    final ReportDraft d = row.draft;
    final String title = row.title.trim().isNotEmpty
        ? row.title.trim()
        : d.title.trim();
    return ReportDraftSummary(
      hasDraft: true,
      photoCount: d.photos.length,
      titlePreview: title.length > 48 ? '${title.substring(0, 45)}…' : title,
      lastPersistedAtMs: row.lastPersistedAtMs ?? row.updatedAtMs,
    );
  }
}
