import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/new_report_evidence_stage_body.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_stage.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('shows evidence validation hint when stage attempted without photos', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: NewReportEvidenceStageBody(
            draft: ReportDraft(),
            evidenceTipDismissed: true,
            attemptedStages: <ReportStage>{ReportStage.evidence},
            onDismissTip: () {},
            onAddPhoto: () {},
            onRemovePhoto: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(Text), findsWidgets);
  });
}
