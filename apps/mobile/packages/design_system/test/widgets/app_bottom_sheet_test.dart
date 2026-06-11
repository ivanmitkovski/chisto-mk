import 'package:design_system/design_system.dart';
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
}
