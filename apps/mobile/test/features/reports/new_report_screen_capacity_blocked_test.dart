import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/reporting_capacity_guard.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('showReportingCooldownDialog is wired (smoke)', (WidgetTester tester) async {
    const ReportCapacity capacity = ReportCapacity(
      creditsAvailable: 0,
      emergencyAvailable: false,
      emergencyWindowDays: 7,
      retryAfterSeconds: 60,
      nextEmergencyReportAvailableAt: null,
      unlockHint: '',
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  showReportingCooldownDialog(context, capacity);
                },
                child: const Text('t'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('t'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(Dialog), findsOneWidget);
  });
}
