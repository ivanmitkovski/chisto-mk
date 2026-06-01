import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/reports_list_screen_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('ReportsListStatsHeader shows add icon and draft chip area', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapForWidgetTest(
        Builder(
          builder: (BuildContext context) {
            return SingleChildScrollView(
              child: ReportsListStatsHeader(
                totalReports: 2,
                underReviewCount: 0,
                reportCapacity: null,
                l10n: AppLocalizations.of(context)!,
                onStartNewReport: () {},
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });
}
