import 'package:chisto_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows report credits card cooldown details', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProfileReportCapacityCard(
            capacity: ReportCapacity(
              creditsAvailable: 0,
              emergencyAvailable: false,
              emergencyWindowDays: 7,
              retryAfterSeconds: 120,
              unlockHint: 'Join eco actions to unlock new credits.',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Report credits'), findsOneWidget);
    expect(find.text('Reporting cooldown active'), findsOneWidget);
    expect(find.textContaining('120s remaining'), findsOneWidget);
  });
}
