import 'dart:ui';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tap just above visible sheet dismisses modal', (
    WidgetTester tester,
  ) async {
    const double screenHeight = 844;
    const double topInset = 59;
    const AppSheetSizeConfig sizeConfig = AppSheetSizeConfig(
      minSize: 0.56,
      maxSize: 0.95,
      snapSizes: <double>[0.74, 0.95],
      initialSize: 0.74,
    );

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

    expect(find.text('Row'), findsOneWidget);

    final RenderBox sheetBox = tester.renderObject<RenderBox>(
      find.byType(AppResizableSheet),
    );
    final double visibleSheetTop = sheetBox.localToGlobal(Offset.zero).dy;
    final Offset tapAboveSheet = Offset(195, visibleSheetTop - 12);

    await tester.tapAt(tapAboveSheet);
    await tester.pumpAndSettle();

    expect(find.text('Row'), findsNothing);
    expect(find.text('Open sheet'), findsOneWidget);
  });
}
