import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_events/src/presentation/widgets/event_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'focused month follows selectedDate when it changes to another month',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: EventCalendar(
              selectedDate: DateTime(2026, 1, 15),
              onDateSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.textContaining('January 2026'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: EventCalendar(
              selectedDate: DateTime(2026, 3, 5),
              onDateSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('March 2026'), findsOneWidget);
    },
  );
}
