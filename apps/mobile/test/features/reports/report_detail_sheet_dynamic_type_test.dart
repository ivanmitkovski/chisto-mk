import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_detail_sheet.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_sheet_view_model.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('detail sheet scales without losing header at 1.6x', (
    WidgetTester tester,
  ) async {
    final ReportSheetViewModel vm = ReportSheetViewModel(
      reportId: 'rid-1',
      title: 'River foam near bridge',
      description: 'River foam near bridge',
      status: ReportSheetStatus.underReview,
      score: 0,
      category: ReportCategory.other,
      createdAt: DateTime(2025, 1, 2),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: Scaffold(body: ReportDetailSheet(report: vm)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Report details'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('River foam near bridge'), findsOneWidget);
  });
}
