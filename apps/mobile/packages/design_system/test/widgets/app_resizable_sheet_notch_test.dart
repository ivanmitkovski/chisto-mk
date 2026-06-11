import 'dart:ui';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('resizable sheet max detent stays below notch in modal route', (
    WidgetTester tester,
  ) async {
    const double screenHeight = 844;
    const double topInset = 59;

    await tester.binding.setSurfaceSize(const Size(390, screenHeight));
    tester.view.physicalSize = const Size(390, screenHeight);
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewPadding = FakeViewPadding(top: topInset, bottom: 34);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewPadding();
    });

    const AppSheetSizeConfig sizeConfig = AppSheetSizeConfig(
      minSize: 0.56,
      maxSize: 0.95,
      snapSizes: <double>[0.74, 0.95],
      initialSize: 0.95,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    AppBottomSheet.showResizable<void>(
                      context: context,
                      sizeConfig: sizeConfig,
                      builder:
                          (
                            BuildContext sheetContext,
                            ScrollController scrollController,
                            DraggableScrollableController sheetController,
                            AppSheetSizeConfig activeConfig,
                          ) {
                            return ListView(
                              controller: scrollController,
                              children: const <Widget>[
                                SizedBox(height: 48, child: Text('Row')),
                              ],
                            );
                          },
                    );
                  },
                  child: const Text('Open sheet'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    final RenderBox sheetBox = tester.renderObject<RenderBox>(
      find.byType(AppResizableSheet),
    );

    expect(
      sheetBox.localToGlobal(Offset.zero).dy,
      closeTo(topInset, 4),
      reason: 'Fully expanded sheet should start below the notch',
    );
    expect(
      sheetBox.size.height,
      closeTo(screenHeight - topInset, 8),
      reason: 'Fully expanded sheet should fill the notch-safe slot',
    );
  });
}
