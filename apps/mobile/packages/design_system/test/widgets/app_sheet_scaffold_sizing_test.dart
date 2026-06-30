import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AppSheetScaffold sizes to content for compact modal sheets', (
    WidgetTester tester,
  ) async {
    const double screenHeight = 844;

    await tester.binding.setSurfaceSize(const Size(390, screenHeight));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, screenHeight)),
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
                            title: 'Take action',
                            subtitle: 'Choose how you want to help',
                            useModalRouteShape: true,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: List<Widget>.generate(
                                3,
                                (int index) => SizedBox(
                                  height: 72,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text('Action $index'),
                                  ),
                                ),
                              ),
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

    final RenderBox sheetBox = tester.renderObject<RenderBox>(
      find.byType(AppSheetScaffold),
    );

    expect(sheetBox.size.height, lessThan(screenHeight * 0.55));
    expect(sheetBox.size.height, greaterThan(280));

    final Rect lastActionRect = tester.getRect(find.text('Action 2'));
    final Rect sheetRect = tester.getRect(
      find.ancestor(
        of: find.text('Take action'),
        matching: find.byWidgetPredicate(
          (Widget widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color ==
                  AppColors.panelBackground,
        ),
      ),
    );
    expect(
      sheetRect.bottom - lastActionRect.bottom,
      lessThan(56),
      reason:
          'Last action row should sit near the sheet bottom without dead band',
    );
  });
}
