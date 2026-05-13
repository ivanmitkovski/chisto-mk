import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';

/// Serializable wizard restore payload for presentation (no SQLite row type).
class ReportWizardRestoreSnapshot {
  const ReportWizardRestoreSnapshot({
    required this.draft,
    required this.title,
    required this.description,
    required this.currentStageName,
    required this.attemptedStageNames,
    required this.lastPersistedAtMs,
    required this.updatedAtMs,
  });

  final ReportDraft draft;
  final String title;
  final String description;
  final String? currentStageName;
  final List<String> attemptedStageNames;
  final int? lastPersistedAtMs;
  final int updatedAtMs;

  /// Same rules as [isReportWizardDraftEntryResumable] in the data layer.
  bool get isResumableWizardBody {
    if (draft.hasPersistableWizardBody) {
      return true;
    }
    if (title.trim().isNotEmpty || description.trim().isNotEmpty) {
      return true;
    }
    final String? stage = currentStageName;
    if (stage != null && stage.isNotEmpty && stage != 'evidence') {
      return true;
    }
    if (attemptedStageNames.isNotEmpty) {
      return true;
    }
    return false;
  }
}
