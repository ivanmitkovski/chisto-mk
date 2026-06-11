import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('hugs its content height (~56) in a normal layout', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: PrimaryButton(label: 'Save', onPressed: () {}),
          ),
        ),
      ),
    );

    final Size size = tester.getSize(find.byType(PrimaryButton));
    expect(size.height, lessThan(80));
    expect(size.height, greaterThanOrEqualTo(56));
  });

  testWidgets(
    'does not expand to fill a bounded Scaffold.bottomNavigationBar slot',
    (WidgetTester tester) async {
      // Regression: a bottomNavigationBar passes bounded height constraints
      // (0..screenHeight). The button must stay a short bar, not fill the
      // screen (which previously hid the body behind a full-screen green pill).
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Center(child: Text('body content')),
            bottomNavigationBar: SafeArea(
              child: PrimaryButton(label: 'Update info', onPressed: () {}),
            ),
          ),
        ),
      );

      final Size screen = tester.getSize(find.byType(Scaffold));
      final Size button = tester.getSize(find.byType(PrimaryButton));

      expect(
        button.height,
        lessThan(80),
        reason: 'PrimaryButton should be a short bar, got ${button.height}',
      );
      expect(
        button.height,
        lessThan(screen.height / 3),
        reason: 'PrimaryButton must not fill the bottom-bar slot',
      );
      expect(find.text('body content'), findsOneWidget);
    },
  );

  testWidgets('grows for a two-line label instead of clipping', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
              child: SizedBox(
                width: 180,
                child: PrimaryButton(
                  label: 'Confirm and submit this very long action label',
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final Size size = tester.getSize(find.byType(PrimaryButton));
    expect(size.height, greaterThanOrEqualTo(56));
  });
}
