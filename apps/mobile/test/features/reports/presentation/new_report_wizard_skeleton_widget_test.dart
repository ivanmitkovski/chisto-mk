import 'package:chisto_mobile/features/reports/presentation/screens/new_report_wizard_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('wizard skeleton lays out without overflow', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NewReportWizardSkeleton(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(NewReportWizardSkeleton), findsOneWidget);
  });
}
