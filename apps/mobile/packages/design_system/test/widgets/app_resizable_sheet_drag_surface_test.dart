import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpDragSurfaceHarness(
    WidgetTester tester, {
    required DraggableScrollableController sheetController,
    required List<Widget> listChildren,
  }) async {
    const AppSheetSizeConfig sizeConfig = AppSheetSizeConfig(
      minSize: 0.56,
      maxSize: 0.95,
      snapSizes: <double>[0.74, 0.95],
      initialSize: 0.74,
    );

    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DraggableScrollableSheet(
            controller: sheetController,
            initialChildSize: 0.74,
            minChildSize: 0.56,
            maxChildSize: 0.95,
            snap: true,
            snapSizes: const <double>[0.74, 0.95],
            builder: (BuildContext context, ScrollController modalScroll) {
              return AppResizableSheet(
                sizeConfig: sizeConfig,
                sheetController: sheetController,
                scrollController: modalScroll,
                builder:
                    (
                      BuildContext context,
                      ScrollController scrollController,
                      DraggableScrollableController sheetController,
                      AppSheetSizeConfig sizeConfig,
                    ) {
                      return AppResizableSheetDragSurface(
                        scrollController: scrollController,
                        sheetController: sheetController,
                        sizeConfig: sizeConfig,
                        child: ListView(
                          controller: scrollController,
                          children: listChildren,
                        ),
                      );
                    },
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('body drag at scroll top resizes the sheet', (
    WidgetTester tester,
  ) async {
    final DraggableScrollableController sheetController =
        DraggableScrollableController();
    addTearDown(sheetController.dispose);

    await pumpDragSurfaceHarness(
      tester,
      sheetController: sheetController,
      listChildren: const <Widget>[
        SizedBox(height: 48, child: Text('Row 1')),
      ],
    );

    expect(sheetController.isAttached, isTrue);
    final double initialSize = sheetController.size;

    await tester.drag(find.text('Row 1'), const Offset(0, 120));
    await tester.pump();

    expect(sheetController.size, lessThan(initialSize));
  });

  testWidgets('body drag does not resize sheet when list is scrolled down', (
    WidgetTester tester,
  ) async {
    final DraggableScrollableController sheetController =
        DraggableScrollableController();
    addTearDown(sheetController.dispose);

    await pumpDragSurfaceHarness(
      tester,
      sheetController: sheetController,
      listChildren: List<Widget>.generate(
        30,
        (int index) => SizedBox(
          height: 48,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Row $index'),
          ),
        ),
      ),
    );

    final Finder scrollable = find.byType(Scrollable);
    await tester.drag(scrollable.first, const Offset(0, -200));
    await tester.pumpAndSettle();

    final double sizeAfterScroll = sheetController.size;

    await tester.scrollUntilVisible(
      find.text('Row 25'),
      48,
      scrollable: scrollable.first,
    );
    await tester.pumpAndSettle();

    await tester.drag(find.text('Row 25'), const Offset(0, 120));
    await tester.pump();

    expect(sheetController.size, closeTo(sizeAfterScroll, 0.02));
  });

  testWidgets('body drag works when scroll controller has no clients', (
    WidgetTester tester,
  ) async {
    final DraggableScrollableController sheetController =
        DraggableScrollableController();
    final ScrollController unattachedScroll = ScrollController();
    addTearDown(sheetController.dispose);
    addTearDown(unattachedScroll.dispose);

    const AppSheetSizeConfig sizeConfig = AppSheetSizeConfig(
      minSize: 0.56,
      maxSize: 0.95,
      snapSizes: <double>[0.74, 0.95],
      initialSize: 0.74,
    );

    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DraggableScrollableSheet(
            controller: sheetController,
            initialChildSize: 0.74,
            minChildSize: 0.56,
            maxChildSize: 0.95,
            snap: true,
            snapSizes: const <double>[0.74, 0.95],
            builder: (BuildContext context, ScrollController modalScroll) {
              return Stack(
                children: <Widget>[
                  ListView(
                    controller: modalScroll,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const <Widget>[SizedBox(height: 1)],
                  ),
                  Positioned.fill(
                    child: AppResizableSheetDragSurface(
                      scrollController: unattachedScroll,
                      sheetController: sheetController,
                      sizeConfig: sizeConfig,
                      child: const Center(child: Text('Empty body')),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(unattachedScroll.hasClients, isFalse);
    expect(sheetController.isAttached, isTrue);
    final double initialSize = sheetController.size;
    await tester.drag(find.text('Empty body'), const Offset(0, 120));
    await tester.pump();

    expect(sheetController.size, lessThan(initialSize));
  });
}
