import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('edge drag past threshold triggers onSwipeBack once', (
    WidgetTester tester,
  ) async {
    var swipeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: EdgeSwipeBack(
          onSwipeBack: () => swipeCount++,
          child: const SizedBox.expand(child: ColoredBox(color: Colors.white)),
        ),
      ),
    );

    await tester.dragFrom(const Offset(10, 300), const Offset(80, 0));
    await tester.pumpAndSettle();

    expect(swipeCount, 1);
  });

  testWidgets('right fling from edge triggers onSwipeBack', (
    WidgetTester tester,
  ) async {
    var swipeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: EdgeSwipeBack(
          onSwipeBack: () => swipeCount++,
          child: const SizedBox.expand(child: ColoredBox(color: Colors.white)),
        ),
      ),
    );

    await tester.flingFrom(const Offset(10, 300), const Offset(120, 0), 800);
    await tester.pumpAndSettle();

    expect(swipeCount, 1);
  });

  testWidgets('drag starting away from edge does not trigger onSwipeBack', (
    WidgetTester tester,
  ) async {
    var swipeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: EdgeSwipeBack(
          onSwipeBack: () => swipeCount++,
          child: const SizedBox.expand(child: ColoredBox(color: Colors.white)),
        ),
      ),
    );

    await tester.dragFrom(const Offset(120, 300), const Offset(180, 0));
    await tester.pumpAndSettle();

    expect(swipeCount, 0);
  });

  testWidgets('short edge drag below threshold does not trigger onSwipeBack', (
    WidgetTester tester,
  ) async {
    var swipeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: EdgeSwipeBack(
          onSwipeBack: () => swipeCount++,
          child: const SizedBox.expand(child: ColoredBox(color: Colors.white)),
        ),
      ),
    );

    await tester.dragFrom(const Offset(10, 300), const Offset(30, 0));
    await tester.pumpAndSettle();

    expect(swipeCount, 0);
  });

  testWidgets('child taps still work outside the edge zone', (
    WidgetTester tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: EdgeSwipeBack(
          onSwipeBack: () {},
          child: Center(
            child: ElevatedButton(
              onPressed: () => tapped = true,
              child: const Text('Continue'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('enabled false never triggers onSwipeBack', (
    WidgetTester tester,
  ) async {
    var swipeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: EdgeSwipeBack(
          enabled: false,
          onSwipeBack: () => swipeCount++,
          child: const SizedBox.expand(child: ColoredBox(color: Colors.white)),
        ),
      ),
    );

    await tester.dragFrom(const Offset(10, 300), const Offset(80, 0));
    await tester.pumpAndSettle();

    expect(swipeCount, 0);
  });
}
