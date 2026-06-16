import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'AppGroupedActionList uses inset dividers not gaps between rows',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGroupedActionList(
              children: <Widget>[
                AppActionTile(
                  variant: AppActionTileVariant.grouped,
                  icon: Icons.cleaning_services,
                  title: 'General cleanup',
                  subtitle: 'Parks and streets',
                  onTap: () {},
                ),
                AppActionTile(
                  variant: AppActionTileVariant.grouped,
                  icon: Icons.water,
                  title: 'River cleanup',
                  subtitle: 'Shores and banks',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(AppGroupedActionList), findsOneWidget);
      expect(find.text('General cleanup'), findsOneWidget);
      expect(find.text('River cleanup'), findsOneWidget);

      final Finder groupedTiles = find.byWidgetPredicate(
        (Widget w) =>
            w is Material &&
            w.color == AppColors.transparent &&
            w.shape is RoundedRectangleBorder,
      );
      expect(groupedTiles, findsNWidgets(2));
    },
  );

  testWidgets('AppActionTile grouped variant omits per-row elevation shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppActionTile(
            variant: AppActionTileVariant.grouped,
            icon: Icons.park,
            title: 'Park',
            onTap: () {},
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(AppActionTile),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).boxShadow != null,
        ),
      ),
      findsNothing,
    );
  });
}
