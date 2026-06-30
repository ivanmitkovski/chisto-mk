import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppCard', () {
    testWidgets('renders child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppCard(child: Text('Card content'))),
        ),
      );

      expect(find.text('Card content'), findsOneWidget);
    });

    testWidgets('applies default border radius', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppCard(child: SizedBox.shrink())),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(AppCard),
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = container.decoration! as BoxDecoration;
      expect(
        decoration.borderRadius,
        equals(BorderRadius.circular(AppSpacing.radiusCard)),
      );
    });

    testWidgets('onTap callback fires when tapped', (
      WidgetTester tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              onTap: () => tapped = true,
              child: const Text('Tap me'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('custom padding is applied', (WidgetTester tester) async {
      const customPadding = EdgeInsets.all(16);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCard(
              padding: customPadding,
              child: Text('Padded content'),
            ),
          ),
        ),
      );

      final cardPadding = find.descendant(
        of: find.byType(AppCard),
        matching: find.byWidgetPredicate(
          (Widget w) => w is Padding && w.padding == customPadding,
        ),
      );
      expect(cardPadding, findsOneWidget);
    });
  });
}
