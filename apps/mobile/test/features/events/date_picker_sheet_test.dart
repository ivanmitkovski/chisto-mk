import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_events/src/presentation/widgets/date_picker_sheet.dart';
import 'package:feature_events/src/presentation/widgets/event_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('confirm returns clamped selected date', (WidgetTester tester) async {
    late AppLocalizations l10n;
    DateTime? result;

    await tester.pumpWidget(
      wrapForWidgetTest(
        Builder(
          builder: (BuildContext context) {
            l10n = AppLocalizations.of(context)!;
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await DatePickerSheet.show(
                      context,
                      title: 'Pick date',
                      initialDate: DateTime(2024, 6, 20),
                      minimumDate: DateTime(2024, 1, 1),
                      maximumDate: DateTime(2024, 12, 31),
                    );
                  },
                  child: const Text('Open date picker'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open date picker'));
    await tester.pumpAndSettle();

    expect(find.byType(EventCalendar), findsOneWidget);
    expect(find.text('Pick date'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(EventCalendar),
        matching: find.text('15'),
      ),
    );
    await tester.pump();

    await tester.tap(find.text(l10n.eventsTimePickerConfirm));
    await tester.pumpAndSettle();

    expect(result, DateTime(2024, 6, 15));
  });

  testWidgets('initial date is clamped to minimumDate', (WidgetTester tester) async {
    late AppLocalizations l10n;

    await tester.pumpWidget(
      wrapForWidgetTest(
        Builder(
          builder: (BuildContext context) {
            l10n = AppLocalizations.of(context)!;
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    DatePickerSheet.show(
                      context,
                      title: 'Pick date',
                      initialDate: DateTime(2019, 5, 1),
                      minimumDate: DateTime(2020, 1, 1),
                      maximumDate: DateTime(2030, 12, 31),
                    );
                  },
                  child: const Text('Open date picker'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open date picker'));
    await tester.pumpAndSettle();

    expect(find.textContaining('January 2020'), findsOneWidget);

    await tester.tap(find.text(l10n.eventsTimePickerConfirm));
    await tester.pumpAndSettle();
  });
}
