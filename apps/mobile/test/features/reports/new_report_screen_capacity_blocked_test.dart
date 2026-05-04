import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/reporting_capacity_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  testWidgets('showReportingCooldownDialog is wired (smoke)', (WidgetTester tester) async {
    await bootstrapWidgetTests();
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
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
  });
}
