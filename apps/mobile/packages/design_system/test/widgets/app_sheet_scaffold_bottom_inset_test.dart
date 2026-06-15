import 'dart:ui';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('scroll body clears home indicator padding', (
    WidgetTester tester,
  ) async {
    const double homeIndicator = 34;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(bottom: homeIndicator),
            viewPadding: EdgeInsets.only(bottom: homeIndicator),
          ),
          child: Builder(
            builder: (BuildContext context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      AppBottomSheet.show<void>(
                        context: context,
                        builder: (BuildContext sheetContext) {
                          return AppSheetScaffold(
                            title: 'Bottom inset test',
                            fillAvailableHeight: true,
                            child: ListView.builder(
                              itemCount: 30,
                              itemBuilder: (BuildContext _, int index) {
                                return SizedBox(
                                  height: 48,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      index == 29
                                          ? 'Last row visible'
                                          : 'Row $index',
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(Scrollable), findsWidgets);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -5000));
    await tester.pumpAndSettle();

    expect(find.text('Last row visible'), findsOneWidget);
    final Offset lastRowPosition = tester.getTopLeft(
      find.text('Last row visible'),
    );
    expect(
      lastRowPosition.dy,
      lessThan(844 - homeIndicator - 48),
      reason: 'Last row should sit above the home indicator zone',
    );
  });

  testWidgets('last scroll row reaches scroll extent not dead zone', (
    WidgetTester tester,
  ) async {
    const double homeIndicator = 34;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            viewPadding: EdgeInsets.only(bottom: homeIndicator),
          ),
          child: SizedBox(
            height: 500,
            child: AppSheetScaffold(
              title: 'Scroll inset',
              maxHeightFactor: 1,
              fillAvailableHeight: true,
              child: ListView.builder(
                itemCount: 20,
                itemBuilder: (BuildContext _, int index) {
                  return SizedBox(
                    height: 48,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        index == 19 ? 'Final scroll row' : 'Row $index',
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.fling(find.byType(Scrollable), const Offset(0, -3000), 2500);
    await tester.pumpAndSettle();

    final ListView listView = tester.widget<ListView>(find.byType(ListView));
    expect(
      listView.padding?.resolve(TextDirection.ltr).bottom,
      homeIndicator,
    );
    expect(find.text('Final scroll row'), findsOneWidget);
  });

  testWidgets('scroll body skips home indicator padding when keyboard is open', (
    WidgetTester tester,
  ) async {
    const double homeIndicator = 34;
    const double keyboardInset = 336;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 844),
            viewPadding: const EdgeInsets.only(bottom: homeIndicator),
            viewInsets: const EdgeInsets.only(bottom: keyboardInset),
          ),
          child: SizedBox(
            height: 500,
            child: AppSheetScaffold(
              title: 'Scroll inset',
              maxHeightFactor: 1,
              fillAvailableHeight: true,
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (BuildContext _, int index) {
                  return SizedBox(
                    height: 48,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Row $index'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    final AppSheetScrollInsets insets = tester.widget<AppSheetScrollInsets>(
      find.byType(AppSheetScrollInsets),
    );
    expect(insets.scrollBottom, 0);
  });

  testWidgets('footer skips home indicator padding when keyboard is open', (
    WidgetTester tester,
  ) async {
    const double homeIndicator = 34;
    const double keyboardInset = 300;

    await tester.binding.setSurfaceSize(const Size(390, 844));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewPadding = const FakeViewPadding(bottom: homeIndicator);
    tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewPadding();
      tester.view.resetViewInsets();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            viewPadding: EdgeInsets.only(bottom: homeIndicator),
            viewInsets: EdgeInsets.only(bottom: keyboardInset),
          ),
          child: SizedBox(
            height: 500,
            child: AppSheetScaffold(
              title: 'Footer inset',
              maxHeightFactor: 1,
              fillAvailableHeight: true,
              padFooterForKeyboard: true,
              addBottomInset: true,
              footer: const PrimaryButton(
                label: 'Save',
                onPressed: null,
              ),
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (BuildContext _, int index) {
                  return SizedBox(
                    height: 48,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Row $index'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    final Finder sheetLiftFinder = find.descendant(
      of: find.byType(AppSheetScaffold),
      matching: find.byType(AnimatedPadding),
    );
    expect(sheetLiftFinder, findsOneWidget);
    final AnimatedPadding sheetLift = tester.widget<AnimatedPadding>(
      sheetLiftFinder,
    );
    expect(
      (sheetLift.padding as EdgeInsets).bottom,
      keyboardInset,
      reason: 'Sheet panel should lift above keyboard outside the painted surface',
    );

    final double keyboardTop = 844 - keyboardInset;
    final Rect footerRect = tester.getRect(find.text('Save'));
    expect(
      footerRect.bottom,
      lessThanOrEqualTo(keyboardTop),
      reason: 'Footer must stay above the keyboard',
    );
    // The keyboard lift now wraps the whole panel from outside the painted
    // surface, so the footer rides that single sheet-level AnimatedPadding
    // rather than stacking its own internal band above the IME.
    final Finder footerLiftFinder = find.ancestor(
      of: find.text('Save'),
      matching: find.byType(AnimatedPadding),
    );
    expect(
      footerLiftFinder,
      findsOneWidget,
      reason:
          'Footer lifts via the single sheet-level AnimatedPadding, not a stacked internal one',
    );
    expect(
      tester.widget<AnimatedPadding>(footerLiftFinder).padding,
      sheetLift.padding,
      reason:
          'Footer shares the sheet-level lift padding (no extra internal band)',
    );
  });

  testWidgets('content-hugging sheet keeps footer close to short body', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AppSheetScaffold(
              title: 'Compact sheet',
              maxHeightFactor: 0.92,
              fillAvailableHeight: false,
              footer: const PrimaryButton(
                label: 'Save',
                onPressed: null,
              ),
              child: SingleChildScrollView(
                child: Text('Short body'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Rect bodyRect = tester.getRect(find.text('Short body'));
    final Rect footerRect = tester.getRect(find.text('Save'));
    expect(
      footerRect.top - bodyRect.bottom,
      lessThanOrEqualTo(AppSpacing.lg + AppSpacing.lg),
      reason: 'Footer should sit directly below content without flex slack',
    );
  });

  testWidgets('fillAvailableHeight fills keyboard slot when keyboard is open', (
    WidgetTester tester,
  ) async {
    const double keyboardInset = 300;
    const double topInset = 59;
    const Size surfaceSize = Size(390, 844);

    await tester.binding.setSurfaceSize(surfaceSize);
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewPadding = const FakeViewPadding(top: topInset);
    tester.view.viewInsets = FakeViewPadding(bottom: keyboardInset);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewPadding();
      tester.view.resetViewInsets();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: surfaceSize.width,
          height: surfaceSize.height,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AppSheetScaffold(
              title: 'Keyboard slot probe',
              maxHeightFactor: 1,
              fillAvailableHeight: true,
              footer: const PrimaryButton(
                label: 'Save',
                onPressed: null,
              ),
              child: const SizedBox(height: 120),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final double expectedSlotCap =
        surfaceSize.height - topInset - keyboardInset;

    final Finder constrained = find.byWidgetPredicate(
      (Widget widget) {
        if (widget is! ConstrainedBox) {
          return false;
        }
        final BoxConstraints c = widget.constraints;
        return c.minHeight > 0 &&
            (c.maxHeight - expectedSlotCap).abs() < 2;
      },
    );
    expect(constrained, findsOneWidget);

    final BoxConstraints constraints =
        tester.widget<ConstrainedBox>(constrained).constraints;
    expect(
      constraints.maxHeight,
      closeTo(expectedSlotCap, 1),
      reason: 'Sheet should expand to fill the keyboard slot',
    );
    expect(
      constraints.minHeight,
      closeTo(expectedSlotCap, 1),
      reason: 'Pinned footer sheets should fill the slot, not shrink-wrap',
    );
  });
}
