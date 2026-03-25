import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_detail_sheet.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_mock_store.dart';
import 'package:chisto_mobile/features/home/presentation/screens/pollution_site_detail_screen.dart';
import 'package:chisto_mobile/shared/testing/widget_test_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ReportSheetHost extends StatefulWidget {
  const _ReportSheetHost({
    required this.report,
    required this.onShowSiteOnMap,
  });

  final MockReport report;
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
        useSafeArea: false,
        backgroundColor: AppColors.transparent,
        builder: (BuildContext context) => ReportDetailSheet(
          report: widget.report,
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

  testWidgets('approved linked site invokes onShowSiteOnMap instead of site detail', (
    WidgetTester tester,
  ) async {
    final List<String> siteIds = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: _ReportSheetHost(
          report: MockReport(
            reportId: 'r1',
            title: 'Report title',
            description: 'Report title',
            status: ReportStatus.approved,
            score: 10,
            category: ReportCategory.other,
            createdAt: DateTime.now(),
            siteId: 'site-xyz',
            address: 'Distinct address for tap target',
          ),
          onShowSiteOnMap: (String id) => siteIds.add(id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PollutionSiteDetailScreen), findsNothing);

    await tester.tap(find.text('Distinct address for tap target'));
    await tester.pumpAndSettle();

    expect(siteIds, <String>['site-xyz']);
    expect(find.byType(PollutionSiteDetailScreen), findsNothing);
  });
}
