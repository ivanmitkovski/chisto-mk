import 'package:chisto_mobile/features/events/presentation/screens/organizer_toolkit/organizer_toolkit_screen.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('OrganizerToolkitScreen shows eight chapters before quiz CTA', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: OrganizerToolkitScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Plan ahead'), findsOneWidget);

    for (int i = 0; i < 7; i++) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Evidence and honest impact'), findsOneWidget);
    expect(find.text('Take the quiz'), findsOneWidget);
  });
}
