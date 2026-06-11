import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppEditorTopBar shows full Macedonian cancel and done labels', (
    WidgetTester tester,
  ) async {
    const String cancelLabel = 'Откажи';
    const String doneLabel = 'Готово';

    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SafeArea(
            child: AppEditorTopBar(
              leadingLabel: cancelLabel,
              onLeadingPressed: () {},
              trailingLabel: doneLabel,
              onTrailingPressed: () {},
              center: const Text('Помести и размери', textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );

    expect(find.text(cancelLabel), findsOneWidget);
    expect(find.text(doneLabel), findsOneWidget);

    final Text cancelText = tester.widget<Text>(find.text(cancelLabel));
    final Text doneText = tester.widget<Text>(find.text(doneLabel));
    expect(cancelText.overflow, TextOverflow.visible);
    expect(doneText.overflow, TextOverflow.visible);
    expect(cancelText.data, cancelLabel);
    expect(doneText.data, doneLabel);
  });

  testWidgets('AppEditorTopBar supports large accessibility text scale', (
    WidgetTester tester,
  ) async {
    const String cancelLabel = 'Откажи';
    const String doneLabel = 'Готово';

    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: Scaffold(
            body: SafeArea(
              child: AppEditorTopBar(
                leadingLabel: cancelLabel,
                onLeadingPressed: () {},
                trailingLabel: doneLabel,
                onTrailingPressed: () {},
                center: const Text('Title', textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text(cancelLabel), findsOneWidget);
    expect(find.text(doneLabel), findsOneWidget);
  });

  testWidgets('AppButton.text does not ellipsis when expand is false', (
    WidgetTester tester,
  ) async {
    const String label = 'Откажи';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: AppButton.text(
              label: label,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    final Text text = tester.widget<Text>(find.text(label));
    expect(text.overflow, TextOverflow.visible);
    expect(text.data, label);
  });
}
