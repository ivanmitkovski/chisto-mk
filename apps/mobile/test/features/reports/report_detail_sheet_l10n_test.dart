import 'package:chisto_mobile/core/di/service_locator.dart';
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

  ReportSheetViewModel _minimalVm() {
    return ReportSheetViewModel(
      reportId: 'rid-1',
      title: 'Title',
      description: 'Title',
      status: ReportSheetStatus.underReview,
      score: 0,
      category: ReportCategory.other,
      createdAt: DateTime(2025, 1, 2),
    );
  }

  testWidgets('detail sheet shows Macedonian copy', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('mk'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ReportDetailSheet(
            report: _minimalVm(),
            reportsRealtimeService:
                ServiceLocator.instance.reportsRealtimeService,
            reportsApiRepository:
                ServiceLocator.instance.reportsApiRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Детали за пријавата'), findsOneWidget);
    expect(find.text('Категорија'), findsOneWidget);
  });

  testWidgets('detail sheet shows Albanian copy', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('sq'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ReportDetailSheet(
            report: _minimalVm(),
            reportsRealtimeService:
                ServiceLocator.instance.reportsRealtimeService,
            reportsApiRepository:
                ServiceLocator.instance.reportsApiRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Detajet e raportit'), findsOneWidget);
    expect(find.text('Kategoria'), findsOneWidget);
  });
}
