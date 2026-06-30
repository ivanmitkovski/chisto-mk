import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/report_detail_sheet.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/report_offline_error_sheet.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/report_sheet_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  ReportSheetViewModel minimalVm() {
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

  testWidgets('detail sheet shows stale banner when opened offline', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ReportDetailSheet(
            report: minimalVm(),
            isStaleFallback: true,
            reportsRealtimeService:
                AppBootstrap.instance.reportsRealtimeService,
            reportsApiRepository: AppBootstrap.instance.reportsApiRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Could not refresh. Showing the last loaded details.'),
      findsOneWidget,
    );
    expect(find.textContaining('Failed host lookup'), findsNothing);
  });

  testWidgets('offline error sheet shows localized copy for network errors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('mk'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return ReportOfflineErrorSheet(
                error: AppError.network(
                  message: "Failed host lookup: 'api.chisto.mk'",
                ),
                onRetry: () {},
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Нема интернет конекција'), findsOneWidget);
    expect(
      find.text('Проверете ја вашата мрежа и обидете се повторно.'),
      findsOneWidget,
    );
    expect(find.textContaining('Failed host lookup'), findsNothing);
    expect(find.text('Обиди се повторно'), findsOneWidget);
    expect(find.text('Назад'), findsOneWidget);
  });
}
