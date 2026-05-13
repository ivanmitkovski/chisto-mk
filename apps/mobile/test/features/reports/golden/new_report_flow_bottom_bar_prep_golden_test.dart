import 'package:chisto_mobile/features/reports/domain/models/report_upload_prep_progress.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/new_report_flow_bottom_bar.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_stage.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  Future<void> pumpBottomBar(WidgetTester tester, Locale locale) async {
    await tester.binding.setSurfaceSize(const Size(420, 220));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(420, 220),
            devicePixelRatio: 1.0,
            textScaler: TextScaler.linear(1.0),
            disableAnimations: true,
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: NewReportFlowBottomBar(
              currentStage: ReportStage.review,
              submitting: true,
              submitPhase: 'uploading',
              uploadPrepProgress: const ReportUploadPrepProgress(completed: 2, total: 5),
              onPrimary: () {},
              onBack: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('NewReportFlowBottomBar prep progress golden en', (WidgetTester tester) async {
    await pumpBottomBar(tester, const Locale('en'));
    await expectLater(
      find.byType(NewReportFlowBottomBar),
      matchesGoldenFile('__goldens__/new_report_flow_bottom_bar_prep_en.png'),
    );
  });

  testWidgets('NewReportFlowBottomBar prep progress golden mk', (WidgetTester tester) async {
    await pumpBottomBar(tester, const Locale('mk'));
    await expectLater(
      find.byType(NewReportFlowBottomBar),
      matchesGoldenFile('__goldens__/new_report_flow_bottom_bar_prep_mk.png'),
    );
  });

  testWidgets('NewReportFlowBottomBar prep progress golden sq', (WidgetTester tester) async {
    await pumpBottomBar(tester, const Locale('sq'));
    await expectLater(
      find.byType(NewReportFlowBottomBar),
      matchesGoldenFile('__goldens__/new_report_flow_bottom_bar_prep_sq.png'),
    );
  });
}
