import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/new_report_evidence_stage_body.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/report_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('shows localized evidence tip when not dismissed', (
    WidgetTester tester,
  ) async {
    final AppLocalizations mkL10n = lookupAppLocalizations(const Locale('mk'));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('mk'),
        home: Scaffold(
          body: NewReportEvidenceStageBody(
            draft: ReportDraft(),
            evidenceTipDismissed: false,
            attemptedStages: const <ReportStage>{},
            onDismissTip: () {},
            onAddPhoto: () {},
            onRemovePhoto: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(mkL10n.reportFlowEvidenceTip), findsOneWidget);
    expect(find.text('Frame the site, good light.'), findsNothing);
  });

  testWidgets(
    'shows evidence validation hint when stage attempted without photos',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: NewReportEvidenceStageBody(
              draft: ReportDraft(),
              evidenceTipDismissed: true,
              attemptedStages: const <ReportStage>{ReportStage.evidence},
              onDismissTip: () {},
              onAddPhoto: () {},
              onRemovePhoto: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Text), findsWidgets);
    },
  );
}
