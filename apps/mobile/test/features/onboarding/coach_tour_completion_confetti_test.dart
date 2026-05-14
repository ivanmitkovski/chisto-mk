import 'package:chisto_mobile/features/onboarding/presentation/coach/coach_tour_completion_confetti.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CoachTourCompletionConfettiLayer has no modal copy', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: CoachTourCompletionConfettiLayer()),
      ),
    );
    await tester.pump();
    expect(find.byType(CoachTourCompletionConfettiLayer), findsOneWidget);
    expect(find.text('You are set'), findsNothing);
    expect(find.text('Готово'), findsNothing);
    await tester.pump(const Duration(milliseconds: 120));
  });
}
