import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_reports/src/domain/models/report_upload_prep_progress.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/new_report_flow_bottom_bar.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/report_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('shows uploading progress when prep progress is set', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: NewReportFlowBottomBar(
            currentStage: ReportStage.review,
            submitting: true,
            submitPhase: 'uploading',
            uploadPrepProgress: const ReportUploadPrepProgress(
              completed: 2,
              total: 5,
            ),
            onPrimary: () {},
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('2'), findsOneWidget);
    expect(find.textContaining('5'), findsOneWidget);
  });
}
