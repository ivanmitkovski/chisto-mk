import 'package:chisto_mobile/features/reports/domain/draft/new_report_flow_policy.dart';
import 'package:chisto_mobile/features/reports/domain/draft/report_stage.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';

/// Wizard session aggregate for the pure reducer (no IO).
class ReportDraftSessionState {
  const ReportDraftSessionState({
    required this.draft,
    required this.currentStage,
    required this.attemptedStages,
    required this.suppressLocalDraftPersist,
    required this.submitting,
    this.lastPersistedAtMs,
  });

  factory ReportDraftSessionState.initial({bool suppressPersist = false}) {
    return ReportDraftSessionState(
      draft: ReportDraft(),
      currentStage: ReportStage.evidence,
      attemptedStages: <ReportStage>{},
      suppressLocalDraftPersist: suppressPersist,
      submitting: false,
      lastPersistedAtMs: null,
    );
  }

  final ReportDraft draft;
  final ReportStage currentStage;
  final Set<ReportStage> attemptedStages;
  final bool suppressLocalDraftPersist;
  final bool submitting;
  final int? lastPersistedAtMs;

  ReportDraftSessionState copyWith({
    ReportDraft? draft,
    ReportStage? currentStage,
    Set<ReportStage>? attemptedStages,
    bool? suppressLocalDraftPersist,
    bool? submitting,
    int? lastPersistedAtMs,
  }) {
    return ReportDraftSessionState(
      draft: draft ?? this.draft,
      currentStage: currentStage ?? this.currentStage,
      attemptedStages: attemptedStages ?? this.attemptedStages,
      suppressLocalDraftPersist:
          suppressLocalDraftPersist ?? this.suppressLocalDraftPersist,
      submitting: submitting ?? this.submitting,
      lastPersistedAtMs: lastPersistedAtMs ?? this.lastPersistedAtMs,
    );
  }

  bool shouldPersistWizardDraft({
    required String titleText,
    required String descriptionText,
  }) {
    if (draft.hasPersistableWizardBody) {
      return true;
    }
    if (titleText.trim().isNotEmpty || descriptionText.trim().isNotEmpty) {
      return true;
    }
    if (currentStage != ReportStage.evidence) {
      return true;
    }
    if (attemptedStages.isNotEmpty) {
      return true;
    }
    return false;
  }

  bool canSubmit() => NewReportFlowPolicy.canSubmit(draft);
}

sealed class ReportDraftSessionEvent {}

final class SessionDraftEdited extends ReportDraftSessionEvent {
  SessionDraftEdited(this.draft);
  final ReportDraft draft;
}

final class SessionStageChanged extends ReportDraftSessionEvent {
  SessionStageChanged(this.stage);
  final ReportStage stage;
}

final class SessionStageAttempted extends ReportDraftSessionEvent {
  SessionStageAttempted(this.stage);
  final ReportStage stage;
}

final class SessionSuppressPersistChanged extends ReportDraftSessionEvent {
  SessionSuppressPersistChanged(this.value);
  final bool value;
}

final class SessionSubmitStarted extends ReportDraftSessionEvent {
  SessionSubmitStarted();
}

final class SessionSubmitEnded extends ReportDraftSessionEvent {
  SessionSubmitEnded();
}

final class SessionPersistRecorded extends ReportDraftSessionEvent {
  SessionPersistRecorded(this.atMs);
  final int atMs;
}

final class SessionCleared extends ReportDraftSessionEvent {
  SessionCleared();
}

final class SessionAutosaveFired extends ReportDraftSessionEvent {
  SessionAutosaveFired({
    required this.titleText,
    required this.descriptionText,
  });
  final String titleText;
  final String descriptionText;
}

sealed class ReportDraftSessionEffect {}

/// UI / IO layer should persist the wizard row (SQLite).
final class EffectPersistWizardDraft extends ReportDraftSessionEffect {
  EffectPersistWizardDraft({
    required this.titleText,
    required this.descriptionText,
  });
  final String titleText;
  final String descriptionText;
}

/// Pure reducer for wizard session rules (tests mirror production intent).
({ReportDraftSessionState state, List<ReportDraftSessionEffect> effects})
reduceReportDraftSession({
  required ReportDraftSessionState state,
  required ReportDraftSessionEvent event,
}) {
  switch (event) {
    case SessionDraftEdited(:final ReportDraft draft):
      return (
        state: state.copyWith(draft: draft),
        effects: const <ReportDraftSessionEffect>[],
      );
    case SessionStageChanged(:final ReportStage stage):
      return (
        state: state.copyWith(currentStage: stage),
        effects: const <ReportDraftSessionEffect>[],
      );
    case SessionStageAttempted(:final ReportStage stage):
      final Set<ReportStage> next = Set<ReportStage>.from(state.attemptedStages)
        ..add(stage);
      return (
        state: state.copyWith(attemptedStages: next),
        effects: const <ReportDraftSessionEffect>[],
      );
    case SessionSuppressPersistChanged(:final bool value):
      return (
        state: state.copyWith(suppressLocalDraftPersist: value),
        effects: const <ReportDraftSessionEffect>[],
      );
    case SessionSubmitStarted():
      final Set<ReportStage> all = Set<ReportStage>.from(ReportStage.values);
      return (
        state: state.copyWith(submitting: true, attemptedStages: all),
        effects: const <ReportDraftSessionEffect>[],
      );
    case SessionSubmitEnded():
      return (
        state: state.copyWith(submitting: false),
        effects: const <ReportDraftSessionEffect>[],
      );
    case SessionPersistRecorded(:final int atMs):
      return (
        state: state.copyWith(lastPersistedAtMs: atMs),
        effects: const <ReportDraftSessionEffect>[],
      );
    case SessionCleared():
      return (
        state: ReportDraftSessionState.initial(),
        effects: const <ReportDraftSessionEffect>[],
      );
    case SessionAutosaveFired(
      :final String titleText,
      :final String descriptionText,
    ):
      if (state.suppressLocalDraftPersist || state.submitting) {
        return (state: state, effects: const <ReportDraftSessionEffect>[]);
      }
      if (!state.shouldPersistWizardDraft(
        titleText: titleText,
        descriptionText: descriptionText,
      )) {
        return (state: state, effects: const <ReportDraftSessionEffect>[]);
      }
      return (
        state: state,
        effects: <ReportDraftSessionEffect>[
          EffectPersistWizardDraft(
            titleText: titleText,
            descriptionText: descriptionText,
          ),
        ],
      );
  }
}
