import 'package:chisto_infrastructure/shared/widgets/organisms/app_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('confirm and cancel return true/false', (
    WidgetTester tester,
  ) async {
    bool? result;

    await tester.pumpWidget(
      wrapForWidgetTest(
        Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await AppConfirmDialog.show(
                      context: context,
                      title: 'Discard event?',
                      body: 'You will lose your input.',
                      confirmLabel: 'Discard',
                      cancelLabel: 'Keep editing',
                      isDestructive: true,
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Discard event?'), findsOneWidget);
    expect(find.text('You will lose your input.'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(result, isFalse);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('showInfo renders a single action button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapForWidgetTest(
        Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    AppConfirmDialog.showInfo(
                      context: context,
                      title: 'Already submitted',
                      body: 'An identical event exists.',
                      confirmLabel: 'Got it',
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Already submitted'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppConfirmDialog),
        matching: find.byType(OutlinedButton),
      ),
      findsNothing,
      reason: 'Info dialog must not render a cancel button',
    );

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Already submitted'), findsNothing);
  });
}
