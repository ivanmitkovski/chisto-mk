import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/data/in_memory_events_store.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_join_toggle_result.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_search_params.dart';
import 'package:chisto_mobile/features/events/domain/models/event_participant_row.dart';
import 'package:chisto_mobile/features/events/domain/models/event_update_payload.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/participants_section.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
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
}
