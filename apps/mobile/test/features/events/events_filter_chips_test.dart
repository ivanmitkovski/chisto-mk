import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_events/src/presentation/widgets/events_filter_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('calls onSelected when tapping inactive filter', (
    WidgetTester tester,
  ) async {
    EcoEventFilter? selected;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: EventsFilterChips(
            active: EcoEventFilter.all,
            onSelected: (EcoEventFilter value) => selected = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Upcoming'));
    await tester.pumpAndSettle();

    expect(selected, equals(EcoEventFilter.upcoming));
  });
}
