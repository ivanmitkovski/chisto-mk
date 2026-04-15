import 'package:chisto_mobile/features/events/presentation/utils/event_recurrence_rrule_summary.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('summarizeRecurrenceRule maps common RRULE fragments', (
    WidgetTester tester,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (BuildContext context) {
            l10n = AppLocalizations.of(context)!;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(summarizeRecurrenceRule('FREQ=WEEKLY', l10n), l10n.eventsRecurrenceWeekly);
    expect(
      summarizeRecurrenceRule('RRULE:FREQ=WEEKLY;INTERVAL=2', l10n),
      l10n.eventsRecurrenceBiweekly,
    );
    expect(summarizeRecurrenceRule('FREQ=MONTHLY', l10n), l10n.eventsRecurrenceMonthly);
    expect(summarizeRecurrenceRule('FREQ=DAILY', l10n), l10n.eventsRecurrenceDaily);
    expect(summarizeRecurrenceRule(null, l10n), isNull);
  });
}
