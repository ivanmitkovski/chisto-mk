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
}
