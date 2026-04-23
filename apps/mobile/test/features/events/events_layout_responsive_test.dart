import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/eco_event_card.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_feed/events_empty_states.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_filter_chips.dart';
import 'package:chisto_mobile/shared/widgets/app_pill_filter_chips.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  EcoEvent buildListCardEvent() {
    return EcoEvent(
      id: 'evt-layout-1',
      title: 'Riverbank cleanup with a moderately long title for wrapping',
      description: 'Test',
      category: EcoEventCategory.generalCleanup,
      siteId: '1',
      siteName: 'Community site near the old bridge and park entrance',
      siteImageUrl: 'assets/test.png',
      siteDistanceKm: 5.0,
      organizerId: 'org-1',
      organizerName: 'Organizer',
      date: DateTime(2025, 6, 15),
      startTime: const EventTime(hour: 10, minute: 0),
      endTime: const EventTime(hour: 12, minute: 0),
      participantCount: 5,
      status: EcoEventStatus.upcoming,
      createdAt: DateTime(2025, 6, 10),
    );
  }

  testWidgets('feed empty state + filter chips + list card tolerate large text',
      (WidgetTester tester) async {
    EcoEventFilter? filter;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.45),
            ),
            child: child!,
          );
        },
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                EventsFilterChips(
                  active: EcoEventFilter.all,
                  onSelected: (EcoEventFilter v) => filter = v,
                ),
                const SizedBox(height: 24),
                const EventsEmptyState(filter: EcoEventFilter.all),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: EcoEventCard(
                    event: buildListCardEvent(),
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(
      find.descendant(
        of: find.byType(AppPillFilterChips),
        matching: find.text('Upcoming'),
      ),
    );
    await tester.pumpAndSettle();
    expect(filter, EcoEventFilter.upcoming);
  });
}
