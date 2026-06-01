import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_events/src/presentation/widgets/events_calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows load-more affordance when month empty and hasMorePages', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int loads = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: EventsCalendarView(
              events: const [],
              onEventTap: (_) {},
              hasMorePages: true,
              onRequestMoreFromServer: () async {
                loads++;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Load more'), findsOneWidget);
    final int afterPrefetch = loads;
    expect(afterPrefetch, 5);
    await tester.ensureVisible(find.text('Load more'));
    await tester.tap(find.text('Load more'));
    await tester.pump();
    expect(loads, afterPrefetch + 1);
  });
}
