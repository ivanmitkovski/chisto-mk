import 'package:chisto_mobile/features/events/data/in_memory_events_store.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/screens/event_detail_screen.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late InMemoryEventsStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store = InMemoryEventsStore.instance;
    store.resetToSeed();
    store.loadInitialIfNeeded();
    await store.ready;
  });

  EcoEvent buildEvent({
    required String id,
    required EcoEventStatus status,
    required bool isJoined,
    required String organizerId,
    bool reminderEnabled = false,
    bool isCheckInOpen = false,
    AttendeeCheckInStatus attendeeCheckInStatus =
        AttendeeCheckInStatus.notCheckedIn,
  }) {
    return EcoEvent(
      id: id,
      title: 'Test event $id',
      description: 'Test event description',
      category: EcoEventCategory.generalCleanup,
      siteId: '1',
      siteName: 'Illegal landfill near the river',
      siteImageUrl: 'assets/images/references/onboarding_reference.png',
      siteDistanceKm: 4,
      organizerId: organizerId,
      organizerName: organizerId == 'current_user' ? 'You' : 'Another organizer',
      date: DateTime.now().add(const Duration(days: 1)),
      startTime: const EventTime(hour: 10, minute: 0),
      endTime: const EventTime(hour: 12, minute: 0),
      participantCount: 8,
      status: status,
      createdAt: DateTime.now(),
      isJoined: isJoined,
      reminderEnabled: reminderEnabled,
      isCheckInOpen: isCheckInOpen,
      attendeeCheckInStatus: attendeeCheckInStatus,
    );
  }

  testWidgets('joined attendee sees reminder action and leave secondary action', (
    WidgetTester tester,
  ) async {
    final EcoEvent event = buildEvent(
      id: 'evt-detail-joined',
      status: EcoEventStatus.upcoming,
      isJoined: true,
      organizerId: 'someone_else',
    );
    store.create(event);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: EventDetailScreen(eventId: event.id),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Set reminder'), findsOneWidget);
    expect(find.text('Leave event'), findsOneWidget);
  });

  testWidgets('in-progress attendee sees scan to check in action', (
    WidgetTester tester,
  ) async {
    final EcoEvent event = buildEvent(
      id: 'evt-detail-checkin',
      status: EcoEventStatus.inProgress,
      isJoined: true,
      organizerId: 'someone_else',
      isCheckInOpen: true,
    );
    store.create(event);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: EventDetailScreen(eventId: event.id),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Scan to check in'), findsOneWidget);
  });
}
