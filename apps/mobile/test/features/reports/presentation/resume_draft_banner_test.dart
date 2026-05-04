import 'package:chisto_mobile/features/reports/data/outbox/report_draft_repository.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_constants.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_entry.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/resume_draft_banner.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('resume banner continue closes dialog', (WidgetTester tester) async {
    final ReportOutboxEntry row = ReportOutboxEntry(
      id: kReportWizardDraftRowId,
      idempotencyKey: 'idem_x',
      draft: ReportDraft(title: 'Hi', photos: const []),
      title: 'Hi',
      description: '',
      submitRequested: false,
      state: ReportOutboxState.pending,
      attemptCount: 0,
      createdAtMs: 1000,
      updatedAtMs: 2000,
      lastPersistedAtMs: 2000,
    );
    final ReportDraftLoadResult load = ReportDraftLoadResult.restored(
      row: row,
      prunedPhotoCount: 0,
      migratedLegacyPhotoCount: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                await showResumeDraftBanner(
                  context: context,
                  l10n: AppLocalizations.of(context)!,
                  loadResult: load,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Continue your draft?'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Continue your draft?'), findsNothing);
  });

  testWidgets('resume banner discard confirms and returns discarded',
      (WidgetTester tester) async {
    final ReportOutboxEntry row = ReportOutboxEntry(
      id: kReportWizardDraftRowId,
      idempotencyKey: 'idem_x',
      draft: ReportDraft(title: 'Hi'),
      title: 'Hi',
      description: '',
      submitRequested: false,
      state: ReportOutboxState.pending,
      attemptCount: 0,
      createdAtMs: 1000,
      updatedAtMs: 2000,
    );
    final ReportDraftLoadResult load = ReportDraftLoadResult.restored(
      row: row,
      prunedPhotoCount: 0,
      migratedLegacyPhotoCount: 0,
    );

    ResumeDraftBannerResult? outcome;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                outcome = await showResumeDraftBanner(
                  context: context,
                  l10n: AppLocalizations.of(context)!,
                  loadResult: load,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard draft'));
    await tester.pumpAndSettle();
    expect(find.text('Discard draft?'), findsOneWidget);
    await tester.tap(find.text('Discard draft'));
    await tester.pumpAndSettle();
    expect(outcome, ResumeDraftBannerResult.discarded);
  });
}
