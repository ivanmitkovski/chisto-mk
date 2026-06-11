import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/report_detail_sheet.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/report_sheet_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  ReportSheetViewModel longVm() {
    return ReportSheetViewModel(
      reportId: 'rid-long',
      title: 'Overflowing Trash Containers',
      description: List<String>.generate(
        40,
        (int i) => 'Line $i of a long description that forces scrolling.',
      ).join('\n'),
      status: ReportSheetStatus.underReview,
      score: 0,
      category: ReportCategory.other,
      createdAt: DateTime(2025, 1, 2),
    );
  }

  testWidgets(
    'scroll viewport reaches the sheet bottom and all content is reachable',
    (WidgetTester tester) async {
      const double screenHeight = 844;
      const double homeIndicatorInset = 34;

      await tester.binding.setSurfaceSize(const Size(390, screenHeight));
      tester.view.physicalSize = const Size(390, screenHeight);
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewPadding = FakeViewPadding(bottom: homeIndicatorInset);
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewPadding();
      });

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ReportDetailSheet(
              report: longVm(),
              reportsRealtimeService:
                  AppBootstrap.instance.reportsRealtimeService,
              reportsApiRepository: AppBootstrap.instance.reportsApiRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No dead strip: the scroll viewport extends to the sheet bottom edge,
      // so content scrolls edge-to-edge instead of clipping early.
      final RenderBox scrollBox = tester.renderObject<RenderBox>(
        find.byType(SingleChildScrollView),
      );
      expect(
        scrollBox.localToGlobal(Offset(0, scrollBox.size.height)).dy,
        closeTo(screenHeight, 0.1),
        reason: 'Viewport must reach the sheet bottom (no clipped strip)',
      );

      // Scroll to the end: the status banner (last content) must be fully
      // visible and clear of the home indicator.
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -4000),
      );
      await tester.pumpAndSettle();

      final Finder banner = find.byType(AppBanner);
      expect(banner, findsOneWidget);
      final RenderBox bannerBox = tester.renderObject<RenderBox>(banner);
      expect(
        bannerBox.localToGlobal(Offset(0, bannerBox.size.height)).dy,
        lessThanOrEqualTo(screenHeight - homeIndicatorInset),
        reason: 'Last content scrolls fully into view above the home '
            'indicator — nothing is cut',
      );

      expect(tester.takeException(), isNull);
    },
  );
}
