import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/report_card.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/report_sheet_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('declined ReportCard shows review note with admin reason', (
    WidgetTester tester,
  ) async {
    const String reason =
        'Insufficient evidence. Notes: The evidence is not enough';

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ReportCard(
            report: ReportSheetViewModel(
              reportId: 'r1',
              title: 'Illegal dump',
              description: 'Illegal dump',
              status: ReportSheetStatus.declined,
              score: 0,
              category: ReportCategory.other,
              createdAt: DateTime(2026, 6, 1),
              declineReason: reason,
            ),
            onTap: () {},
            formatDate: (_) => 'Jun 1',
          ),
        ),
      ),
    );

    expect(find.text('Review note'), findsOneWidget);
    expect(find.textContaining('Insufficient evidence'), findsOneWidget);
    expect(find.textContaining('The evidence is not enough'), findsOneWidget);
  });
}
