import 'dart:ui';

import 'package:design_system/design_system.dart';
import 'package:design_system/src/widgets/organisms/app_panel_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openSheet(
    WidgetTester tester, {
    bool dismissible = true,
    Future<bool> Function()? canDismiss,
    required VoidCallback onClose,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.show<void>(
                      context: context,
                      dismissible: dismissible,
                      canDismiss: canDismiss,
                      builder: (BuildContext sheetContext) {
                        return AppSheetScaffold(
                          title: 'Test sheet',
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              onClose();
                              Navigator.of(sheetContext).pop();
                            },
                          ),
                          child: const Text('Sheet body'),
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
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('AppBottomSheet.show opens and closes via X', (
    WidgetTester tester,
  ) async {
    var closed = false;
    await openSheet(tester, onClose: () => closed = true);
    expect(find.text('Sheet body'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(find.text('Sheet body'), findsNothing);
  });

  testWidgets('dismissible:false blocks scrim dismiss', (
    WidgetTester tester,
  ) async {
    await openSheet(tester, dismissible: false, onClose: () {});
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.text('Sheet body'), findsOneWidget);
  });

  testWidgets('homeIndicatorScrollPadding includes view padding', (
    WidgetTester tester,
  ) async {
    late double padding;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(viewPadding: EdgeInsets.only(bottom: 34)),
        child: Builder(
          builder: (BuildContext context) {
            padding = AppBottomSheet.homeIndicatorScrollPadding(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(padding, 34 + AppSpacing.sm);
  });

  testWidgets('footer applies home indicator padding once on footer widget', (
    WidgetTester tester,
  ) async {
    const double homeIndicator = 34;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            viewPadding: EdgeInsets.only(bottom: homeIndicator),
          ),
          child: AppSheetScaffold(
            title: 'Footer inset test',
            footer: AppButton.primary(
              label: 'Confirm action',
              onPressed: () {},
            ),
            child: const SizedBox(height: 120),
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (Widget widget) => widget is SizedBox && widget.height == homeIndicator,
      ),
      findsNothing,
      reason: 'Post-footer SizedBox inset should not duplicate footer padding',
    );

    expect(
      find.ancestor(
        of: find.text('Confirm action'),
        matching: find.byWidgetPredicate(
          (Widget widget) =>
              widget is Padding &&
              widget.padding is EdgeInsets &&
              (widget.padding as EdgeInsets).bottom == homeIndicator,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('overlay sheet title stays below the notch', (
    WidgetTester tester,
  ) async {
    const double topInset = 59;

    await tester.binding.setSurfaceSize(const Size(390, 844));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewPadding = const FakeViewPadding(top: topInset);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewPadding();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.show<void>(
                      context: context,
                      keyboardInsetMode: SheetKeyboardInsetMode.overlay,
                      maxHeightFactor: 1,
                      builder: (BuildContext sheetContext) {
                        return AppSheetScaffold(
                          title: 'Notch probe',
                          fillAvailableHeight: true,
                          child: const SizedBox(height: 200),
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
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final Offset titleTopLeft = tester.getTopLeft(find.text('Notch probe'));
    expect(
      titleTopLeft.dy,
      greaterThanOrEqualTo(topInset + AppSpacing.xs - 1),
      reason: 'Sheet title must render below the platform top safe area',
    );
  });

  testWidgets('lift mode sheet title stays below the notch', (
    WidgetTester tester,
  ) async {
    const double topInset = 59;

    await tester.binding.setSurfaceSize(const Size(390, 844));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewPadding = const FakeViewPadding(top: topInset);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewPadding();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.show<void>(
                      context: context,
                      keyboardInsetMode: SheetKeyboardInsetMode.lift,
                      maxHeightFactor: 1,
                      builder: (BuildContext sheetContext) {
                        return AppSheetScaffold(
                          title: 'Lift notch probe',
                          fillAvailableHeight: true,
                          child: const SizedBox(height: 200),
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
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final Offset titleTopLeft = tester.getTopLeft(
      find.text('Lift notch probe'),
    );
    expect(
      titleTopLeft.dy,
      greaterThanOrEqualTo(topInset + AppSpacing.xs - 1),
      reason:
          'Lift-mode sheet title must render below the platform top safe area',
    );
  });

  testWidgets('overlay sheet lifts footer when view metrics change', (
    WidgetTester tester,
  ) async {
    const double keyboardInset = 300;

    await tester.binding.setSurfaceSize(const Size(390, 844));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewInsets = FakeViewPadding.zero;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.show<void>(
                      context: context,
                      keyboardInsetMode: SheetKeyboardInsetMode.overlay,
                      builder: (BuildContext sheetContext) {
                        return AppSheetScaffold(
                          title: 'Keyboard probe',
                          fillAvailableHeight: true,
                          padFooterForKeyboard: true,
                          footer: const PrimaryButton(
                            label: 'Save',
                            onPressed: null,
                          ),
                          child: const SizedBox(height: 200),
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
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(AnimatedPadding), findsNothing);

    tester.view.viewInsets = FakeViewPadding(bottom: keyboardInset);
    await tester.pump();

    final Finder liftFinder = find.byType(AnimatedPadding);
    expect(liftFinder, findsOneWidget);
    expect(
      (tester.widget<AnimatedPadding>(liftFinder).padding as EdgeInsets).bottom,
      keyboardInset,
    );
  });

  testWidgets('lift mode keeps text field focus when keyboard metrics change', (
    WidgetTester tester,
  ) async {
    const double keyboardInset = 300;

    await tester.binding.setSurfaceSize(const Size(390, 844));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewInsets = FakeViewPadding.zero;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.show<void>(
                      context: context,
                      keyboardInsetMode: SheetKeyboardInsetMode.lift,
                      builder: (BuildContext sheetContext) {
                        return AppSheetScaffold(
                          title: 'Lift keyboard probe',
                          fillAvailableHeight: true,
                          padFooterForKeyboard: false,
                          child: const TextField(
                            decoration: InputDecoration(hintText: 'Type here'),
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
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final Finder field = find.byType(TextField);
    await tester.tap(field);
    await tester.pump();

    EditableText editableText(WidgetTester t) {
      return t.widget<EditableText>(find.byType(EditableText));
    }

    expect(editableText(tester).focusNode.hasFocus, isTrue);

    tester.view.viewInsets = FakeViewPadding(bottom: keyboardInset);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(editableText(tester).focusNode.hasFocus, isTrue);
  });
}
