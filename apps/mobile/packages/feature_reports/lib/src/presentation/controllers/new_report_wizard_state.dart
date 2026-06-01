import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:feature_reports/src/domain/models/report_capacity.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/report_stage.dart';

/// Immutable wizard UI state for [NewReportController].
class NewReportWizardState {
  NewReportWizardState({
    ReportDraft? draft,
    this.submitting = false,
    this.submitPhase,
    this.isProcessingPhotoFlow = false,
    this.evidenceTipDismissed = false,
    Set<ReportStage>? attemptedStages,
    this.currentStage = ReportStage.evidence,
    this.highlightedStage,
    this.didAnnounceLocationStep = false,
    this.apiError,
    this.reportCapacity,
    this.reportFlowPrefsLoaded = false,
    this.hasSeenReportHelpHint = true,
    this.lastPersistedAtMs,
    this.restoreError,
    this.incomingPhotoMergeResolved = true,
    this.suppressLocalDraftPersist = false,
  }) : draft = draft ?? ReportDraft(),
       attemptedStages = attemptedStages ?? <ReportStage>{};

  final ReportDraft draft;
  final bool submitting;
  final String? submitPhase;
  final bool isProcessingPhotoFlow;
  final bool evidenceTipDismissed;
  final Set<ReportStage> attemptedStages;
  final ReportStage currentStage;
  final ReportStage? highlightedStage;
  final bool didAnnounceLocationStep;
  final AppError? apiError;
  final ReportCapacity? reportCapacity;
  final bool reportFlowPrefsLoaded;
  final bool hasSeenReportHelpHint;
  final int? lastPersistedAtMs;
  final Object? restoreError;
  final bool incomingPhotoMergeResolved;
  final bool suppressLocalDraftPersist;

  NewReportWizardState copyWith({
    ReportDraft? draft,
    bool? submitting,
    String? submitPhase,
    bool clearSubmitPhase = false,
    bool? isProcessingPhotoFlow,
    bool? evidenceTipDismissed,
    Set<ReportStage>? attemptedStages,
    ReportStage? currentStage,
    ReportStage? highlightedStage,
    bool clearHighlightedStage = false,
    bool? didAnnounceLocationStep,
    AppError? apiError,
    bool clearApiError = false,
    ReportCapacity? reportCapacity,
    bool? reportFlowPrefsLoaded,
    bool? hasSeenReportHelpHint,
    int? lastPersistedAtMs,
    Object? restoreError,
    bool clearRestoreError = false,
    bool? incomingPhotoMergeResolved,
    bool? suppressLocalDraftPersist,
  }) {
    return NewReportWizardState(
      draft: draft ?? this.draft,
      submitting: submitting ?? this.submitting,
      submitPhase: clearSubmitPhase ? null : (submitPhase ?? this.submitPhase),
      isProcessingPhotoFlow:
          isProcessingPhotoFlow ?? this.isProcessingPhotoFlow,
      evidenceTipDismissed: evidenceTipDismissed ?? this.evidenceTipDismissed,
      attemptedStages: attemptedStages ?? this.attemptedStages,
      currentStage: currentStage ?? this.currentStage,
      highlightedStage: clearHighlightedStage
          ? null
          : (highlightedStage ?? this.highlightedStage),
      didAnnounceLocationStep:
          didAnnounceLocationStep ?? this.didAnnounceLocationStep,
      apiError: clearApiError ? null : (apiError ?? this.apiError),
      reportCapacity: reportCapacity ?? this.reportCapacity,
      reportFlowPrefsLoaded:
          reportFlowPrefsLoaded ?? this.reportFlowPrefsLoaded,
      hasSeenReportHelpHint:
          hasSeenReportHelpHint ?? this.hasSeenReportHelpHint,
      lastPersistedAtMs: lastPersistedAtMs ?? this.lastPersistedAtMs,
      restoreError: clearRestoreError
          ? null
          : (restoreError ?? this.restoreError),
      incomingPhotoMergeResolved:
          incomingPhotoMergeResolved ?? this.incomingPhotoMergeResolved,
      suppressLocalDraftPersist:
          suppressLocalDraftPersist ?? this.suppressLocalDraftPersist,
    );
  }
}
