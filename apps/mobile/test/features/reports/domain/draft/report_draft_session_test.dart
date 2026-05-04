import 'package:chisto_mobile/features/reports/domain/draft/report_draft_session.dart';
import 'package:chisto_mobile/features/reports/domain/draft/report_stage.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  group('reduceReportDraftSession', () {
    test('SessionDraftEdited updates draft', () {
      final ReportDraftSessionState s0 = ReportDraftSessionState.initial();
      final ReportDraft next = ReportDraft(title: 'A');
      final ({ReportDraftSessionState state, List<ReportDraftSessionEffect> effects}) r =
          reduceReportDraftSession(
        state: s0,
        event: SessionDraftEdited(next),
      );
      expect(r.state.draft.title, 'A');
      expect(r.effects, isEmpty);
    });

    test('SessionStageChanged updates currentStage', () {
      final ReportDraftSessionState s0 = ReportDraftSessionState.initial();
      final ({ReportDraftSessionState state, List<ReportDraftSessionEffect> effects}) r =
          reduceReportDraftSession(
        state: s0,
        event: SessionStageChanged(ReportStage.review),
      );
      expect(r.state.currentStage, ReportStage.review);
      expect(r.effects, isEmpty);
    });

    test('SessionStageAttempted accumulates stages', () {
      ReportDraftSessionState s = ReportDraftSessionState.initial();
      s = reduceReportDraftSession(
        state: s,
        event: SessionStageAttempted(ReportStage.details),
      ).state;
      s = reduceReportDraftSession(
        state: s,
        event: SessionStageAttempted(ReportStage.location),
      ).state;
      expect(s.attemptedStages, containsAll(<ReportStage>[ReportStage.details, ReportStage.location]));
    });

    test('SessionSubmitStarted sets submitting and marks all stages attempted', () {
      final ReportDraftSessionState s0 = ReportDraftSessionState.initial();
      final ({ReportDraftSessionState state, List<ReportDraftSessionEffect> effects}) r =
          reduceReportDraftSession(
        state: s0,
        event: SessionSubmitStarted(),
      );
      expect(r.state.submitting, isTrue);
      expect(r.state.attemptedStages.length, ReportStage.values.length);
      expect(r.effects, isEmpty);
    });

    test('SessionSubmitEnded clears submitting', () {
      final ReportDraftSessionState s0 = reduceReportDraftSession(
        state: ReportDraftSessionState.initial(),
        event: SessionSubmitStarted(),
      ).state;
      final ({ReportDraftSessionState state, List<ReportDraftSessionEffect> effects}) r =
          reduceReportDraftSession(
        state: s0,
        event: SessionSubmitEnded(),
      );
      expect(r.state.submitting, isFalse);
      expect(r.effects, isEmpty);
    });

    test('SessionPersistRecorded sets lastPersistedAtMs', () {
      final ({ReportDraftSessionState state, List<ReportDraftSessionEffect> effects}) r =
          reduceReportDraftSession(
        state: ReportDraftSessionState.initial(),
        event: SessionPersistRecorded(42),
      );
      expect(r.state.lastPersistedAtMs, 42);
      expect(r.effects, isEmpty);
    });

    test('SessionCleared resets to initial', () {
      final ReportDraftSessionState s0 = reduceReportDraftSession(
        state: ReportDraftSessionState.initial(),
        event: SessionDraftEdited(ReportDraft(title: 'X')),
      ).state;
      final ({ReportDraftSessionState state, List<ReportDraftSessionEffect> effects}) r =
          reduceReportDraftSession(
        state: s0,
        event: SessionCleared(),
      );
      expect(r.state.draft.title, isEmpty);
      expect(r.state.currentStage, ReportStage.evidence);
      expect(r.effects, isEmpty);
    });

    test('SessionAutosaveFired emits persist when body is persistable', () {
      final ReportDraftSessionState s0 = ReportDraftSessionState.initial().copyWith(
        draft: ReportDraft(photos: <XFile>[XFile('p.jpg')]),
      );
      final ({ReportDraftSessionState state, List<ReportDraftSessionEffect> effects}) r =
          reduceReportDraftSession(
        state: s0,
        event: SessionAutosaveFired(titleText: '', descriptionText: ''),
      );
      expect(r.effects, hasLength(1));
      expect(r.effects.single, isA<EffectPersistWizardDraft>());
      final EffectPersistWizardDraft e = r.effects.single as EffectPersistWizardDraft;
      expect(e.titleText, '');
      expect(e.descriptionText, '');
    });

    test('SessionAutosaveFired emits persist when title or description non-empty', () {
      final ReportDraftSessionState s0 = ReportDraftSessionState.initial();
      final ({ReportDraftSessionState state, List<ReportDraftSessionEffect> effects}) r =
          reduceReportDraftSession(
        state: s0,
        event: SessionAutosaveFired(titleText: '  t  ', descriptionText: ''),
      );
      expect(r.effects, hasLength(1));
      expect(r.effects.single, isA<EffectPersistWizardDraft>());
    });

    test('SessionAutosaveFired persists when past evidence even with empty texts', () {
      final ReportDraftSessionState s0 = ReportDraftSessionState.initial().copyWith(
        currentStage: ReportStage.details,
      );
      final ({ReportDraftSessionState state, List<ReportDraftSessionEffect> effects}) r =
          reduceReportDraftSession(
        state: s0,
        event: SessionAutosaveFired(titleText: '', descriptionText: ''),
      );
      expect(r.effects, hasLength(1));
      expect(r.effects.single, isA<EffectPersistWizardDraft>());
    });

    test('SessionAutosaveFired no effect when suppressLocalDraftPersist', () {
      final ReportDraftSessionState s0 = ReportDraftSessionState.initial().copyWith(
        draft: ReportDraft(title: 'A'),
        suppressLocalDraftPersist: true,
      );
      final ({ReportDraftSessionState state, List<ReportDraftSessionEffect> effects}) r =
          reduceReportDraftSession(
        state: s0,
        event: SessionAutosaveFired(titleText: '', descriptionText: ''),
      );
      expect(r.effects, isEmpty);
    });

    test('SessionAutosaveFired no effect when submitting', () {
      final ReportDraftSessionState s0 = ReportDraftSessionState.initial().copyWith(
        draft: ReportDraft(title: 'A'),
        submitting: true,
      );
      final ({ReportDraftSessionState state, List<ReportDraftSessionEffect> effects}) r =
          reduceReportDraftSession(
        state: s0,
        event: SessionAutosaveFired(titleText: '', descriptionText: ''),
      );
      expect(r.effects, isEmpty);
    });

    test('SessionSuppressPersistChanged toggles flag', () {
      final ({ReportDraftSessionState state, List<ReportDraftSessionEffect> effects}) r =
          reduceReportDraftSession(
        state: ReportDraftSessionState.initial(),
        event: SessionSuppressPersistChanged(true),
      );
      expect(r.state.suppressLocalDraftPersist, isTrue);
    });
  });

  group('ReportDraftSessionState.shouldPersistWizardDraft', () {
    test('true when attemptedStages non-empty even on evidence with empty texts', () {
      final ReportDraftSessionState s = ReportDraftSessionState.initial().copyWith(
        attemptedStages: <ReportStage>{ReportStage.details},
      );
      expect(s.shouldPersistWizardDraft(titleText: '', descriptionText: ''), isTrue);
    });
  });
}
