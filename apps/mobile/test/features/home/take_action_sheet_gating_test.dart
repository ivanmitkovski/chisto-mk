import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/presentation/widgets/take_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('hides the create-eco-action tile when canCreateEcoAction is false', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(const TakeActionSheet(canCreateEcoAction: false)));
    await tester.pumpAndSettle();
    // Only Join + Share remain.
    expect(find.byType(AppActionTile), findsNWidgets(2));
  });

  testWidgets('shows the create-eco-action tile when canCreateEcoAction is true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(const TakeActionSheet(canCreateEcoAction: true)));
    await tester.pumpAndSettle();
    // Create + Join + Share.
    expect(find.byType(AppActionTile), findsNWidgets(3));
  });
}
