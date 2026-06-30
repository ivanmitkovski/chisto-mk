import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('vertical stack shows full Macedonian button labels', (
    WidgetTester tester,
  ) async {
    const String retake = 'Сними повторно';
    const String confirm = 'Потврди фотографија';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSheetFooterActions(
            secondary: AppButton.outlined(
              label: retake,
              onPressed: () {},
              expand: true,
            ),
            primary: AppButton.primary(
              label: confirm,
              onPressed: () {},
              expand: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text(retake), findsOneWidget);
    expect(find.text(confirm), findsOneWidget);
    expect(find.textContaining('...'), findsNothing);
  });
}
