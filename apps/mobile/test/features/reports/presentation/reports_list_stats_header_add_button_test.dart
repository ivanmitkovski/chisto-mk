import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/reports_list_screen_header.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
      MaterialApp(
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(
          body: Builder(
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
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });
}
