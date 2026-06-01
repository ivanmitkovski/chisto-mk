import 'package:design_system/design_system.dart';
import 'package:feature_home/src/presentation/widgets/map/map_sheet_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('showMapBottomSheet lays out below the top safe area', (
    WidgetTester tester,
  ) async {
    const double topInset = 59;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(top: topInset),
            viewPadding: EdgeInsets.only(top: topInset),
          ),
          child: Builder(
            builder: (BuildContext context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showMapBottomSheet<void>(
                        context: context,
                        builder: (BuildContext sheetContext) {
                          return const DecoratedBox(
                            decoration: BoxDecoration(color: Colors.white),
                            child: SizedBox(
                              height: 400,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Text('Map sheet probe'),
                              ),
                            ),
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
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    final Finder probe = find.text('Map sheet probe');
    expect(probe, findsOneWidget);

    final Offset probeTopLeft = tester.getTopLeft(probe);
    expect(probeTopLeft.dy, greaterThanOrEqualTo(topInset + AppSpacing.sm - 1));
  });
}
