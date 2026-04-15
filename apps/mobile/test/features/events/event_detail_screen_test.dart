import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/data/in_memory_events_store.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/screens/event_detail_screen.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail_skeleton.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/title_section.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late InMemoryEventsStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store = InMemoryEventsStore.instance;
    EventsRepositoryRegistry.setTestOverride(store);
    store.resetToSeed();
    store.loadInitialIfNeeded();
    await store.ready;
  });

  tearDown(() {
    store.simulateDetailPrefetchFailureOnForce = false;
    EventsRepositoryRegistry.setTestOverride(null);
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
    bool moderationApproved = true,
    String? recurrenceRule,
    int? recurrenceSeriesTotal,
    int? recurrenceSeriesPosition,
    double? siteLat,
    double? siteLng,
    int? maxParticipants,
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
      siteLat: siteLat,
      siteLng: siteLng,
      organizerId: organizerId,
      organizerName: organizerId == 'current_user' ? 'You' : 'Another organizer',
      date: DateTime.now().add(const Duration(days: 1)),
      startTime: const EventTime(hour: 10, minute: 0),
      endTime: const EventTime(hour: 12, minute: 0),
      participantCount: 8,
      maxParticipants: maxParticipants,
      status: status,
      createdAt: DateTime.now(),
      isJoined: isJoined,
      reminderEnabled: reminderEnabled,
      isCheckInOpen: isCheckInOpen,
      attendeeCheckInStatus: attendeeCheckInStatus,
      moderationApproved: moderationApproved,
      recurrenceRule: recurrenceRule,
      recurrenceSeriesTotal: recurrenceSeriesTotal,
      recurrenceSeriesPosition: recurrenceSeriesPosition,
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
    await store.create(event);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: EventDetailScreen(eventsRepository: store, eventId: event.id),
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
    await store.create(event);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: EventDetailScreen(eventsRepository: store, eventId: event.id),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Scan to check in'), findsOneWidget);
  });

  testWidgets('organizer with approved upcoming event sees Start event CTA', (
    WidgetTester tester,
  ) async {
    final EcoEvent event = buildEvent(
      id: 'evt-detail-organizer',
      status: EcoEventStatus.upcoming,
      isJoined: true,
      organizerId: 'current_user',
      moderationApproved: true,
    );
    await store.create(event);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: EventDetailScreen(eventsRepository: store, eventId: event.id),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Start event'), findsOneWidget);
  });

  testWidgets('detail shows RefreshIndicator', (WidgetTester tester) async {
    final EcoEvent event = buildEvent(
      id: 'evt-refresh',
      status: EcoEventStatus.upcoming,
      isJoined: false,
      organizerId: 'someone_else',
    );
    await store.create(event);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: EventDetailScreen(eventsRepository: store, eventId: event.id),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('recurring event shows localized series label when total known', (
    WidgetTester tester,
  ) async {
    final EcoEvent event = buildEvent(
      id: 'evt-series',
      status: EcoEventStatus.upcoming,
      isJoined: false,
      organizerId: 'someone_else',
      recurrenceRule: 'FREQ=WEEKLY',
      recurrenceSeriesTotal: 3,
      recurrenceSeriesPosition: 2,
    );
    await store.create(event);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: EventDetailScreen(eventsRepository: store, eventId: event.id),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Event 2 of 3'), findsOneWidget);
    expect(find.text('Every week'), findsOneWidget);
  });

  testWidgets('location row exposes Open in Maps when coordinates set', (
    WidgetTester tester,
  ) async {
    final EcoEvent event = buildEvent(
      id: 'evt-maps',
      status: EcoEventStatus.upcoming,
      isJoined: false,
      organizerId: 'someone_else',
      siteLat: 41.9965,
      siteLng: 21.4314,
    );
    await store.create(event);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: EventDetailScreen(eventsRepository: store, eventId: event.id),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Open in Maps'), findsOneWidget);
  });

  testWidgets('title section shows localized date and time range subtitle', (
    WidgetTester tester,
  ) async {
    final EcoEvent event = buildEvent(
      id: 'evt-title-subtitle',
      status: EcoEventStatus.upcoming,
      isJoined: false,
      organizerId: 'someone_else',
    );
    await store.create(event);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: EventDetailScreen(eventsRepository: store, eventId: event.id),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TitleSection), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TitleSection),
        matching: find.textContaining('10:00 - 12:00'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('missing event shows not-found layout with browse action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            disableAnimations: true,
          ),
          child: EventDetailScreen(eventsRepository: store, eventId: 'does-not-exist'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EventDetailSkeleton), findsNothing);
    expect(find.text('Browse events'), findsOneWidget);
  });

  testWidgets('pending moderation organizer sees moderation banner', (
    WidgetTester tester,
  ) async {
    final EcoEvent event = buildEvent(
      id: 'evt-moderation',
      status: EcoEventStatus.upcoming,
      isJoined: true,
      organizerId: 'current_user',
      moderationApproved: false,
    );
    await store.create(event);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: EventDetailScreen(eventsRepository: store, eventId: event.id),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Awaiting approval'), findsWidgets);
  });

  testWidgets('stale refresh banner when forced prefetch fails with cache', (
    WidgetTester tester,
  ) async {
    store.simulateDetailPrefetchFailureOnForce = true;
    final EcoEvent event = buildEvent(
      id: 'evt-stale-banner',
      status: EcoEventStatus.upcoming,
      isJoined: false,
      organizerId: 'someone_else',
    );
    await store.create(event);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: EventDetailScreen(eventsRepository: store, eventId: event.id),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('detail renders at increased text scale without throwing', (
    WidgetTester tester,
  ) async {
    final EcoEvent event = buildEvent(
      id: 'evt-text-scale',
      status: EcoEventStatus.upcoming,
      isJoined: true,
      organizerId: 'someone_else',
    );
    await store.create(event);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(400, 900),
            textScaler: TextScaler.linear(1.45),
          ),
          child: EventDetailScreen(eventsRepository: store, eventId: event.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TitleSection), findsOneWidget);
  });

  testWidgets('organizer completed event shows after-photos CTA label', (
    WidgetTester tester,
  ) async {
    final EcoEvent event = buildEvent(
      id: 'evt-completed-organizer',
      status: EcoEventStatus.completed,
      isJoined: true,
      organizerId: 'current_user',
    );
    await store.create(event);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: EventDetailScreen(eventsRepository: store, eventId: event.id),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Upload after photos'), findsOneWidget);
  });

  testWidgets('detail renders when MediaQuery disableAnimations is true', (
    WidgetTester tester,
  ) async {
    final EcoEvent event = buildEvent(
      id: 'evt-reduce-motion',
      status: EcoEventStatus.upcoming,
      isJoined: false,
      organizerId: 'someone_else',
    );
    await store.create(event);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            disableAnimations: true,
          ),
          child: EventDetailScreen(eventsRepository: store, eventId: event.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TitleSection), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TitleSection),
        matching: find.textContaining('10:00 - 12:00'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'rapid detail route replacement with thumbnail hero off does not throw',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: EventDetailScreen(
            eventsRepository: store,
            eventId: 'evt-1',
            enableThumbnailHero: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final NavigatorState nav = tester.state<NavigatorState>(
        find.byType(Navigator),
      );

      for (int i = 0; i < 10; i++) {
        final String id = i.isEven ? 'evt-1' : 'evt-2';
        nav.pushReplacement(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => EventDetailScreen(
              eventsRepository: store,
              eventId: id,
              enableThumbnailHero: false,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TitleSection), findsOneWidget);
    },
  );
}
