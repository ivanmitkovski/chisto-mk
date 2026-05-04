import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_entry.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';

/// True if the SQLite wizard row should drive resume UI / block SP import, etc.
bool isReportWizardDraftEntryResumable(ReportOutboxEntry row) {
  final ReportDraft d = row.draft;
  if (d.hasPersistableWizardBody) {
    return true;
  }
  if (row.title.trim().isNotEmpty || row.description.trim().isNotEmpty) {
    return true;
  }
  final String? stage = row.currentStageName;
  if (stage != null && stage.isNotEmpty && stage != 'evidence') {
    return true;
  }
  if (row.attemptedStageNames.isNotEmpty) {
    return true;
  }
  return false;
}

/// Pure projection of [ReportDraftSummary] from a wizard row (no IO).
class ReportDraftSummaryProjector {
  const ReportDraftSummaryProjector._();

  static ReportDraftSummary fromWizardRow(ReportOutboxEntry? row) {
    if (row == null) {
      return const ReportDraftSummary(
        hasDraft: false,
        photoCount: 0,
        titlePreview: '',
        lastPersistedAtMs: 0,
      );
    }
    if (!isReportWizardDraftEntryResumable(row)) {
      return const ReportDraftSummary(
        hasDraft: false,
        photoCount: 0,
        titlePreview: '',
        lastPersistedAtMs: 0,
      );
    }
    final ReportDraft d = row.draft;
    final String title =
        row.title.trim().isNotEmpty ? row.title.trim() : d.title.trim();
    return ReportDraftSummary(
      hasDraft: true,
      photoCount: d.photos.length,
      titlePreview: title.length > 48 ? '${title.substring(0, 45)}…' : title,
      lastPersistedAtMs: row.lastPersistedAtMs ?? row.updatedAtMs,
    );
  }
}

/// Summary for resume UI (no PII beyond counts and title preview).
class ReportDraftSummary {
  const ReportDraftSummary({
    required this.hasDraft,
    required this.photoCount,
    required this.titlePreview,
    required this.lastPersistedAtMs,
  });

  final bool hasDraft;
  final int photoCount;
  final String titlePreview;
  final int lastPersistedAtMs;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ReportDraftSummary &&
        other.hasDraft == hasDraft &&
        other.photoCount == photoCount &&
        other.titlePreview == titlePreview &&
        other.lastPersistedAtMs == lastPersistedAtMs;
  }

  @override
  int get hashCode => Object.hash(hasDraft, photoCount, titlePreview, lastPersistedAtMs);
}
