import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/new_report_flow_header.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_stage.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('shows draft restored chip when enabled', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: NewReportFlowHeader(
            title: 'Report',
            currentStage: ReportStage.evidence,
            currentStageIndex: 0,
            isStageComplete: (_) => false,
            canNavigateToStage: (_) => true,
            onBackFromEvidence: () {},
            onBackToPreviousStage: () {},
            onTapStage: (_) {},
            showDraftRestoredChip: true,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Draft restored'), findsOneWidget);
  });
}
