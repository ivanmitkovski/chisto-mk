import 'package:chisto_mobile/features/reports/data/outbox/report_draft_summary_projector.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_constants.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_entry.dart'
    show ReportOutboxEntry, ReportOutboxState;
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

ReportOutboxEntry _wizardRow({
  ReportDraft? draft,
  String title = '',
  String description = '',
  String? currentStageName,
  List<String> attemptedStageNames = const <String>[],
  int updatedAtMs = 5000,
  int? lastPersistedAtMs,
}) {
  return ReportOutboxEntry(
    id: kReportWizardDraftRowId,
    idempotencyKey: 'idem_$kReportWizardDraftRowId',
    draft: draft ?? ReportDraft(),
    title: title,
    description: description,
    submitRequested: false,
    state: ReportOutboxState.pending,
    attemptCount: 0,
    createdAtMs: 1,
    updatedAtMs: updatedAtMs,
    currentStageName: currentStageName,
    attemptedStageNames: attemptedStageNames,
    lastPersistedAtMs: lastPersistedAtMs,
  );
}

void main() {
  group('isReportWizardDraftEntryResumable', () {
    test('false for empty wizard body and metadata', () {
      expect(isReportWizardDraftEntryResumable(_wizardRow()), isFalse);
    });

    test('true when title set on row', () {
      expect(isReportWizardDraftEntryResumable(_wizardRow(title: ' Hi ')), isTrue);
    });

    test('true when description set on row', () {
      expect(isReportWizardDraftEntryResumable(_wizardRow(description: 'x')), isTrue);
    });

    test('true when stage past evidence', () {
      expect(
        isReportWizardDraftEntryResumable(_wizardRow(currentStageName: 'location')),
        isTrue,
      );
    });

    test('false when stage evidence explicitly', () {
      expect(
        isReportWizardDraftEntryResumable(_wizardRow(currentStageName: 'evidence')),
        isFalse,
      );
    });

    test('true when attempted stages recorded', () {
      expect(
        isReportWizardDraftEntryResumable(
          _wizardRow(attemptedStageNames: <String>['details']),
        ),
        isTrue,
      );
    });

    test('true when draft has photos', () {
      final ReportDraft d = ReportDraft(photos: <XFile>[XFile('a.jpg')]);
      expect(isReportWizardDraftEntryResumable(_wizardRow(draft: d)), isTrue);
    });
  });

  group('ReportDraftSummaryProjector.fromWizardRow', () {
    test('null row yields empty summary', () {
      expect(
        ReportDraftSummaryProjector.fromWizardRow(null),
        const ReportDraftSummary(
          hasDraft: false,
          photoCount: 0,
          titlePreview: '',
          lastPersistedAtMs: 0,
        ),
      );
    });

    test('non-resumable row yields empty summary', () {
      expect(ReportDraftSummaryProjector.fromWizardRow(_wizardRow()).hasDraft, isFalse);
    });

    test('uses row title and lastPersistedAtMs when set', () {
      final ReportDraftSummary s = ReportDraftSummaryProjector.fromWizardRow(
        _wizardRow(
          title: 'My title',
          draft: ReportDraft(title: 'ignored'),
          lastPersistedAtMs: 777,
          updatedAtMs: 888,
        ),
      );
      expect(s.hasDraft, isTrue);
      expect(s.titlePreview, 'My title');
      expect(s.lastPersistedAtMs, 777);
    });

    test('falls back to draft title when row title empty', () {
      final ReportDraftSummary s = ReportDraftSummaryProjector.fromWizardRow(
        _wizardRow(
          draft: ReportDraft(title: 'From draft'),
          attemptedStageNames: <String>['details'],
        ),
      );
      expect(s.titlePreview, 'From draft');
    });

    test('truncates long title preview', () {
      final String longTitle = 'T' * 52;
      final ReportDraftSummary s = ReportDraftSummaryProjector.fromWizardRow(
        _wizardRow(title: longTitle, attemptedStageNames: <String>['details']),
      );
      expect(s.titlePreview.length, lessThan(longTitle.length));
      expect(s.titlePreview.endsWith('…'), isTrue);
    });

    test('photoCount from draft', () {
      final ReportDraftSummary s = ReportDraftSummaryProjector.fromWizardRow(
        _wizardRow(
          draft: ReportDraft(
            photos: <XFile>[XFile('1'), XFile('2')],
          ),
          attemptedStageNames: <String>['details'],
        ),
      );
      expect(s.photoCount, 2);
    });

    test('uses updatedAtMs when lastPersistedAtMs null', () {
      final ReportDraftSummary s = ReportDraftSummaryProjector.fromWizardRow(
        _wizardRow(
          title: 'x',
          updatedAtMs: 12345,
          lastPersistedAtMs: null,
        ),
      );
      expect(s.lastPersistedAtMs, 12345);
    });
  });
}
