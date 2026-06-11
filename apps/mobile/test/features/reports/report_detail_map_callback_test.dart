import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/presentation/screens/pollution_site_detail_screen.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/report_detail_sheet.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/report_sheet_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

class _ReportSheetHost extends StatefulWidget {
  const _ReportSheetHost({required this.report, required this.onShowSiteOnMap});

  final ReportSheetViewModel report;
  final void Function(String siteId) onShowSiteOnMap;

  @override
  State<_ReportSheetHost> createState() => _ReportSheetHostState();
}

class _ReportSheetHostState extends State<_ReportSheetHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppBottomSheet.show<void>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: false,
        backgroundColor: AppColors.transparent,
        builder: (BuildContext context) => ReportDetailSheet(
          report: widget.report,
          reportsRealtimeService: AppBootstrap.instance.reportsRealtimeService,
          reportsApiRepository: AppBootstrap.instance.reportsApiRepository,
          onShowSiteOnMap: widget.onShowSiteOnMap,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }
}

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets(
    'approved linked site invokes onShowSiteOnMap instead of site detail',
    (WidgetTester tester) async {
      final List<String> siteIds = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _ReportSheetHost(
            report: ReportSheetViewModel(
              reportId: 'r1',
              title: 'Report title',
              description: 'Report title',
              status: ReportSheetStatus.approved,
              score: 10,
              category: ReportCategory.other,
              createdAt: DateTime.now(),
              siteId: 'site-xyz',
              address: 'Distinct address for tap target',
            ),
            onShowSiteOnMap: siteIds.add,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PollutionSiteDetailScreen), findsNothing);

      await tester.tap(find.text('Distinct address for tap target'));
      await tester.pumpAndSettle();

      expect(siteIds, <String>['site-xyz']);
      expect(find.byType(PollutionSiteDetailScreen), findsNothing);
    },
  );

  testWidgets('close control dismisses modal sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _ReportSheetHost(
          report: ReportSheetViewModel(
            reportId: 'r2',
            title: 'T',
            description: 'T',
            status: ReportSheetStatus.underReview,
            score: 0,
            category: ReportCategory.other,
            createdAt: DateTime.now(),
          ),
          onShowSiteOnMap: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(ReportDetailSheet), findsNothing);
  });

  testWidgets('status banner stays above home indicator when scrolled to end', (
    WidgetTester tester,
  ) async {
    const double homeIndicator = 34;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(bottom: homeIndicator),
            viewPadding: EdgeInsets.only(bottom: homeIndicator),
          ),
          child: _ReportSheetHost(
            report: ReportSheetViewModel(
              reportId: 'r3',
              title: 'Long report title for layout',
              description: 'Long report description text',
              status: ReportSheetStatus.underReview,
              score: 4,
              category: ReportCategory.airPollution,
              severity: 4,
              cleanupEffort: CleanupEffort.threeToFive,
              createdAt: DateTime(2026, 6, 8),
              reportNumber: 'CH-000073',
              address: 'Skopje test address',
            ),
            onShowSiteOnMap: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder bannerTitle = find.text('Under review by moderators');
    expect(bannerTitle, findsOneWidget);

    await tester.fling(find.byType(Scrollable).first, const Offset(0, -800), 2000);
    await tester.pumpAndSettle();

    expect(bannerTitle, findsOneWidget);
    expect(
      tester.getBottomLeft(bannerTitle).dy,
      lessThan(844 - homeIndicator),
    );
  });

  testWidgets('report detail subtitle and status body are fully visible', (
    WidgetTester tester,
  ) async {
    const double homeIndicator = 34;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            viewPadding: EdgeInsets.only(bottom: homeIndicator),
          ),
          child: _ReportSheetHost(
            report: ReportSheetViewModel(
              reportId: 'r4',
              title: 'Long report title for layout',
              description: 'Long report description text',
              status: ReportSheetStatus.underReview,
              score: 4,
              category: ReportCategory.airPollution,
              severity: 4,
              cleanupEffort: CleanupEffort.threeToFive,
              createdAt: DateTime(2026, 6, 8),
              reportNumber: 'CH-000073',
              address: 'Skopje test address',
            ),
            onShowSiteOnMap: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const String subtitlePrefix = 'CH-000073 · See what you submitted';
    expect(find.textContaining(subtitlePrefix), findsOneWidget);

    final Text subtitleText = tester.widget<Text>(
      find.textContaining(subtitlePrefix),
    );
    expect(subtitleText.overflow, isNot(TextOverflow.ellipsis));

    final Finder statusBody = find.text(
      'Moderators are checking your evidence and location before they decide how to handle this report.',
    );
    expect(statusBody, findsOneWidget);

    await tester.fling(find.byType(Scrollable).first, const Offset(0, -1200), 2500);
    await tester.pumpAndSettle();

    expect(statusBody, findsOneWidget);
    expect(
      tester.getBottomLeft(statusBody).dy,
      lessThan(844 - homeIndicator),
    );
  });
}
