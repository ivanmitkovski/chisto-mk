import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_events/src/presentation/widgets/event_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _calendarApp(EventCalendar calendar) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: calendar),
  );
}

Finder _dayInCalendar(String dayLabel) {
  return find.descendant(
    of: find.byType(EventCalendar),
    matching: find.text(dayLabel),
  );
}

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

  testWidgets('past dates are selectable when minimumSelectableDate allows them', (
    WidgetTester tester,
  ) async {
    DateTime? picked;

    await tester.pumpWidget(
      _calendarApp(
        EventCalendar(
          selectedDate: DateTime(2024, 1, 15),
          minimumSelectableDate: DateTime(2020, 1, 1),
          onDateSelected: (DateTime d) => picked = d,
        ),
      ),
    );

    expect(find.textContaining('January 2024'), findsOneWidget);

    await tester.tap(_dayInCalendar('10'));
    await tester.pump();

    expect(picked, DateTime(2024, 1, 10));
  });

  testWidgets('default bounds block day before today', (WidgetTester tester) async {
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    if (today.day <= 1) {
      return;
    }

    DateTime? picked;

    await tester.pumpWidget(
      _calendarApp(
        EventCalendar(
          selectedDate: today,
          onDateSelected: (DateTime d) => picked = d,
        ),
      ),
    );

    await tester.tap(_dayInCalendar('${today.day - 1}'));
    await tester.pump();
    expect(picked, isNull);

    await tester.tap(_dayInCalendar('${today.day}'));
    await tester.pump();
    expect(picked, today);
  });

  testWidgets('next month navigation is disabled at maximumSelectableDate', (
    WidgetTester tester,
  ) async {
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final DateTime maxDate = DateTime(
      today.year,
      today.month,
      DateUtils.getDaysInMonth(today.year, today.month),
    );

    await tester.pumpWidget(
      _calendarApp(
        EventCalendar(
          selectedDate: today,
          maximumSelectableDate: maxDate,
          onDateSelected: (_) {},
        ),
      ),
    );

    final MaterialLocalizations loc = MaterialLocalizations.of(
      tester.element(find.byType(EventCalendar)),
    );
    final String monthLabel = loc.formatMonthYear(today);
    expect(find.text(monthLabel), findsOneWidget);

    await tester.tap(find.byTooltip('Next month'));
    await tester.pump();

    expect(find.text(monthLabel), findsOneWidget);
  });
}
