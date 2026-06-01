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
      showModalBottomSheet<void>(
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
}
