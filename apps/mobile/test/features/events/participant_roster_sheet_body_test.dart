import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/data/in_memory_events_store.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_join_toggle_result.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_search_params.dart';
import 'package:chisto_mobile/features/events/domain/models/event_participant_row.dart';
import 'package:chisto_mobile/features/events/domain/models/event_schedule_conflict_preview.dart';
import 'package:chisto_mobile/features/events/domain/models/event_update_payload.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/participants_section.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/user_avatar_circle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [InMemoryEventsStore.fetchParticipants] completes in a microtask, so the roster
/// sheet often skips the loading frame in widget tests. Delay only this call so we
/// can assert spinner → list.
class _DelayedParticipantsRepo implements EventsRepository {
  _DelayedParticipantsRepo(this._inner);

  final InMemoryEventsStore _inner;

  @override
  void addListener(VoidCallback listener) => _inner.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _inner.removeListener(listener);

  @override
  List<EcoEvent> get events => _inner.events;

  @override
  DateTime? get lastSuccessfulListRefreshAt =>
      _inner.lastSuccessfulListRefreshAt;

  @override
  bool get hasMoreEvents => _inner.hasMoreEvents;

  @override
  bool get lastGlobalListLoadFailed => _inner.lastGlobalListLoadFailed;

  @override
  bool get isShowingStaleCachedEvents => _inner.isShowingStaleCachedEvents;

  @override
  bool get isReady => _inner.isReady;

  @override
  Future<void> get ready => _inner.ready;

  @override
  void loadInitialIfNeeded() => _inner.loadInitialIfNeeded();

  @override
  Future<void> refreshEvents({EcoEventSearchParams? params}) =>
      _inner.refreshEvents(params: params);

  @override
  Future<bool> prefetchEvent(String id, {bool force = false}) =>
      _inner.prefetchEvent(id, force: force);

  @override
  Future<void> prefetchEventsForSite(String siteId) =>
      _inner.prefetchEventsForSite(siteId);

  @override
  void resetToSeed() => _inner.resetToSeed();

  @override
  EcoEvent? findById(String id) => _inner.findById(id);

  @override
  EcoEvent? findBySiteAndTitle({
    required String siteId,
    required String title,
  }) =>
      _inner.findBySiteAndTitle(siteId: siteId, title: title);

  @override
  Future<EcoEvent> create(EcoEvent event) => _inner.create(event);

  @override
  Future<EventScheduleConflictPreview> checkScheduleConflict({
    required String siteId,
    required DateTime scheduledAt,
    DateTime? endAt,
    String? excludeEventId,
  }) =>
      _inner.checkScheduleConflict(
        siteId: siteId,
        scheduledAt: scheduledAt,
        endAt: endAt,
        excludeEventId: excludeEventId,
      );

  @override
  Future<EcoEvent> updateEventDetails(
    String eventId,
    EventUpdatePayload payload,
  ) =>
      _inner.updateEventDetails(eventId, payload);

  @override
  Future<bool> updateStatus(String id, EcoEventStatus status) =>
      _inner.updateStatus(id, status);

  @override
  Future<EcoEventJoinToggleResult> toggleJoin(String id) => _inner.toggleJoin(id);

  @override
  bool setCheckInOpen({
    required String eventId,
    required bool isOpen,
  }) =>
      _inner.setCheckInOpen(eventId: eventId, isOpen: isOpen);

  @override
  bool rotateCheckInSession({
    required String eventId,
    required String sessionId,
  }) =>
      _inner.rotateCheckInSession(eventId: eventId, sessionId: sessionId);

  @override
  bool setCheckedInCount({
    required String eventId,
    required int checkedInCount,
  }) =>
      _inner.setCheckedInCount(eventId: eventId, checkedInCount: checkedInCount);

  @override
  bool setAttendeeCheckInStatus({
    required String eventId,
    required AttendeeCheckInStatus status,
    DateTime? checkedInAt,
  }) =>
      _inner.setAttendeeCheckInStatus(
        eventId: eventId,
        status: status,
        checkedInAt: checkedInAt,
      );

  @override
  Future<bool> setReminder({
    required String eventId,
    required bool enabled,
    DateTime? reminderAt,
  }) =>
      _inner.setReminder(
        eventId: eventId,
        enabled: enabled,
        reminderAt: reminderAt,
      );

  @override
  Future<bool> setAfterImages({
    required String eventId,
    required List<String> imagePaths,
  }) =>
      _inner.setAfterImages(eventId: eventId, imagePaths: imagePaths);

  @override
  Future<void> loadMore() => _inner.loadMore();

  @override
  Future<EventParticipantsPage> fetchParticipants(
    String eventId, {
    String? cursor,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 16));
    return _inner.fetchParticipants(eventId, cursor: cursor);
  }
}

void main() {
  late InMemoryEventsStore store;
  late _DelayedParticipantsRepo delayedRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store = InMemoryEventsStore.instance;
    delayedRepo = _DelayedParticipantsRepo(store);
    EventsRepositoryRegistry.setTestOverride(delayedRepo);
    store.resetToSeed();
    store.loadInitialIfNeeded();
    await store.ready;
  });

  tearDown(() {
    EventsRepositoryRegistry.setTestOverride(null);
  });

  testWidgets('shows loading then participant list from repository', (
    WidgetTester tester,
  ) async {
    final EcoEvent event = store.findById('evt-1')!;
    expect(event.participantCount, greaterThan(0));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: ParticipantRosterSheetBody(event: event),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Volunteer 1'), findsOneWidget);
  });

  test('mergeParticipantPreviews skips API row that duplicates organizer id', () {
    final EcoEvent event = store.findById('evt-1')!;
    final List<EventParticipantRow> rows = <EventParticipantRow>[
      EventParticipantRow(
        userId: event.organizerId,
        displayName: event.organizerName,
        joinedAt: DateTime.utc(2024, 1, 1),
      ),
      EventParticipantRow(
        userId: 'volunteer-extra',
        displayName: 'Alex',
        joinedAt: DateTime.utc(2024, 1, 2),
      ),
    ];
    final List<AttendeePreview> merged = mergeParticipantPreviews(
      event: event,
      apiRows: rows,
      youLabel: 'You',
    );
    expect(merged.length, 2);
    expect(merged.where((AttendeePreview a) => a.userId == event.organizerId).length, 1);
    expect(merged.any((AttendeePreview a) => a.userId == 'volunteer-extra'), isTrue);
  });

  test('orderPreviewsForAvatarStack puts joiners before organizers', () {
    final EcoEvent event = store.findById('evt-1')!;
    final List<AttendeePreview> merged = mergeParticipantPreviews(
      event: event,
      apiRows: <EventParticipantRow>[
        EventParticipantRow(
          userId: 'joiner-a',
          displayName: 'Alex',
          joinedAt: DateTime.utc(2024, 1, 2),
        ),
      ],
      youLabel: 'You',
    );
    expect(merged.first.isOrganizer, isTrue);
    final List<AttendeePreview> ordered = orderPreviewsForAvatarStack(merged);
    expect(ordered.first.userId, 'joiner-a');
    expect(ordered.last.isOrganizer, isTrue);
  });

  testWidgets('ParticipantsSection shows multiple avatars after participant peek', (
    WidgetTester tester,
  ) async {
    final EcoEvent event = store.findById('evt-1')!;
    expect(event.participantCount, greaterThan(1));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: ParticipantsSection(event: event),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pumpAndSettle();

    expect(find.byType(UserAvatarCircle), findsAtLeastNWidgets(2));
  });

  testWidgets('AvatarStack pads circles when count exceeds fetched preview rows', (
    WidgetTester tester,
  ) async {
    final EcoEvent base = store.findById('evt-1')!;
    final EcoEvent event = base.copyWith(participantCount: 2);
    final List<AttendeePreview> previews = mergeParticipantPreviews(
      event: event,
      apiRows: const <EventParticipantRow>[],
      youLabel: 'You',
    );
    expect(previews.length, 1);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Center(
            child: AvatarStack(
              count: 2,
              event: event,
              previews: previews,
              isLoadingPeek: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(UserAvatarCircle), findsNWidgets(2));
  });

  testWidgets(
    'AvatarStack shows joiner and organizer when participantCount is one joiner',
    (WidgetTester tester) async {
      final EcoEvent base = store.findById('evt-1')!;
      final EcoEvent event = base.copyWith(participantCount: 1);
      final List<AttendeePreview> previews = mergeParticipantPreviews(
        event: event,
        apiRows: <EventParticipantRow>[
          EventParticipantRow(
            userId: 'joiner-sam',
            displayName: 'Sam Joiner',
            joinedAt: DateTime.utc(2024, 1, 3),
          ),
        ],
        youLabel: 'You',
      );
      expect(previews.length, 2);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Center(
              child: AvatarStack(
                count: 1,
                event: event,
                previews: previews,
                isLoadingPeek: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(UserAvatarCircle), findsNWidgets(2));
      final List<UserAvatarCircle> avatars = tester
          .widgetList<UserAvatarCircle>(find.byType(UserAvatarCircle))
          .toList();
      expect(avatars.first.displayName, 'Sam Joiner');
    },
  );
}
