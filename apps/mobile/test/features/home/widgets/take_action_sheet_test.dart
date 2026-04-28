import 'package:chisto_mobile/features/home/presentation/widgets/take_action_sheet.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const List<LocalizationsDelegate<dynamic>> _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

MaterialApp _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: _delegates,
    supportedLocales: const <Locale>[Locale('en')],
    home: Scaffold(body: child),
  );
}

void main() {
  group('TakeActionSheet', () {
    testWidgets('shows create, join and share actions', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const TakeActionSheet()));
      await tester.pumpAndSettle();

      expect(find.text('Create eco action'), findsOneWidget);
      expect(find.text('Join action'), findsOneWidget);
      expect(find.text('Share site'), findsOneWidget);
    });

    testWidgets('does not show donate action', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const TakeActionSheet()));
      await tester.pumpAndSettle();

      expect(find.text('Donate / contribute'), findsNothing);
    });
  });
}
