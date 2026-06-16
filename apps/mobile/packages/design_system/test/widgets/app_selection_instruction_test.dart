import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('uses header semantics and is not a button', (
    WidgetTester tester,
  ) async {
    const String message = 'Tap each item volunteers should bring.';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppSelectionInstruction(
            message: message,
            showDividerBelow: false,
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(AppSelectionInstruction)),
      matchesSemantics(isHeader: true, label: message, isButton: false),
    );
  });

  testWidgets('combines label and message for screen readers', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppSelectionInstruction(
            label: 'Hint',
            message: 'Pick one option.',
            showDividerBelow: false,
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(AppSelectionInstruction)),
      matchesSemantics(isHeader: true, label: 'Hint. Pick one option.'),
    );
  });

  testWidgets('optional icon renders inline without separate semantics node', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppSelectionInstruction(
            message: 'Guidance text',
            icon: Icons.info_outline,
            showDividerBelow: false,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(AppSelectionInstruction)),
      matchesSemantics(isHeader: true, label: 'Guidance text'),
    );
  });

  testWidgets('has no ink well in subtree', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppSelectionInstruction(
            message: 'Non-interactive guidance',
            showDividerBelow: false,
          ),
        ),
      ),
    );

    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('shows divider when showDividerBelow is true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppSelectionInstruction(message: 'With divider')),
      ),
    );

    expect(find.byType(Divider), findsOneWidget);
  });
}
