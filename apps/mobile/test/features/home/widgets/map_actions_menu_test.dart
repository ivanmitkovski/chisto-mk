import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chisto_mobile/features/home/presentation/widgets/map/map_actions_menu.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

void main() {
  testWidgets('opens menu and shows action semantics', (WidgetTester tester) async {
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
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Center map on my location'), findsOneWidget);
  });
}
