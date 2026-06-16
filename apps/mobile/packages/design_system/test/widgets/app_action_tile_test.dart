import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'AppActionTile uses clipped Material surface without Ink decoration',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          ),
          home: Scaffold(
            backgroundColor: AppColors.overlay,
            body: Center(
              child: AppActionTile(
                icon: Icons.map_rounded,
                title: 'Google Maps',
                subtitle: 'Web and Google Maps app.',
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Ink), findsNothing);
      final Finder surfaceMaterial = find.descendant(
        of: find.byType(AppActionTile),
        matching: find.byWidgetPredicate(
          (Widget w) => w is Material && w.color == AppColors.inputFill,
        ),
      );
      expect(surfaceMaterial, findsOneWidget);
      expect(
        tester.widget<Material>(surfaceMaterial).clipBehavior,
        Clip.antiAlias,
      );
      final DecoratedBox shadowWrapper = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(AppActionTile),
          matching: find.byWidgetPredicate(
            (Widget w) =>
                w is DecoratedBox &&
                w.decoration is BoxDecoration &&
                (w.decoration! as BoxDecoration).boxShadow != null,
          ),
        ),
      );
      expect(
        (shadowWrapper.decoration as BoxDecoration).borderRadius,
        BorderRadius.circular(AppSpacing.radius18),
      );
    },
  );

  testWidgets('AppActionTile compact variant omits elevation shadow wrapper', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppActionTile(
            icon: Icons.link,
            title: 'Copy link',
            onTap: () {},
            variant: AppActionTileVariant.compact,
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
              (w.decoration! as BoxDecoration).boxShadow != null,
        ),
      ),
      findsNothing,
    );
  });
}
