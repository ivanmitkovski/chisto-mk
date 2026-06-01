import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_home/src/presentation/widgets/map/map_actions_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens menu and shows action semantics', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: MapActionsMenu(
            showHeatmap: false,
            useDarkTiles: false,
            isLocating: false,
            locationJustFound: false,
            rotationLocked: false,
            onToggleHeatmap: () {},
            onToggleDarkTiles: () {},
            onZoomToFit: () {},
            onToggleRotationLock: () {},
            onLocateMe: () {},
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Open actions menu'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Open actions menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.bySemanticsLabel('Center map on my location'), findsOneWidget);
  });
}
