import 'package:chisto_mobile/features/events/data/in_memory_events_store.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/event_participant_row.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late InMemoryEventsStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store = InMemoryEventsStore.instance;
    store.resetToSeed();
  });

  test('updateStatus does not start before scheduled time', () async {
    await store.create(
      EcoEvent(
        id: 'evt-too-early',
        title: 'Later',
        description: 'D',
        category: EcoEventCategory.generalCleanup,
        siteId: '1',
        siteName: 'S',
        siteImageUrl: '',
        siteDistanceKm: 1,
        organizerId: 'current_user',
        organizerName: 'Me',
        date: DateTime(2035, 7, 1),
        startTime: const EventTime(hour: 10, minute: 0),
        endTime: const EventTime(hour: 12, minute: 0),
        participantCount: 0,
        status: EcoEventStatus.upcoming,
        createdAt: DateTime.now(),
        scheduledAtUtc: DateTime.utc(2035, 7, 1, 8, 0),
      ),
    );
    final bool ok =
        await store.updateStatus('evt-too-early', EcoEventStatus.inProgress);
    expect(ok, isFalse);
    expect(store.findById('evt-too-early')!.status, EcoEventStatus.upcoming);
  });

  test('enforces lifecycle transitions', () async {
    final EcoEvent? initial = store.findById('evt-1');
    expect(initial, isNotNull);
    expect(initial!.status, equals(EcoEventStatus.upcoming));

    final bool skipToCompleted =
        await store.updateStatus('evt-1', EcoEventStatus.completed);
    expect(skipToCompleted, isFalse);
    expect(store.findById('evt-1')!.status, equals(EcoEventStatus.upcoming));

    final bool start = await store.updateStatus('evt-1', EcoEventStatus.inProgress);
    expect(start, isTrue);
    expect(store.findById('evt-1')!.status, equals(EcoEventStatus.inProgress));

    final bool complete = await store.updateStatus('evt-1', EcoEventStatus.completed);
    expect(complete, isTrue);
    expect(store.findById('evt-1')!.status, equals(EcoEventStatus.completed));
  });

  test('sets and clears event reminder', () async {
    final DateTime at = DateTime(2026, 1, 1, 9, 0);
    final bool enabled = await store.setReminder(
      eventId: 'evt-1',
      enabled: true,
      reminderAt: at,
    );
    expect(enabled, isTrue);
    expect(store.findById('evt-1')!.reminderEnabled, isTrue);
    expect(store.findById('evt-1')!.reminderAt, equals(at));

    final bool disabled = await store.setReminder(
      eventId: 'evt-1',
      enabled: false,
      reminderAt: null,
    );
    expect(disabled, isTrue);
    expect(store.findById('evt-1')!.reminderEnabled, isFalse);
    expect(store.findById('evt-1')!.reminderAt, isNull);
  });

  test('saves organizer after images', () async {
    final bool updated = await store.setAfterImages(
      eventId: 'evt-1',
      imagePaths: <String>['/tmp/a.jpg', '/tmp/b.jpg'],
    );
    expect(updated, isTrue);
    expect(store.findById('evt-1')!.afterImagePaths.length, equals(2));

    final bool noOp = await store.setAfterImages(
      eventId: 'evt-1',
      imagePaths: <String>['/tmp/a.jpg', '/tmp/b.jpg'],
    );
    expect(noOp, isFalse);
  });

  test('fetchParticipants returns synthetic rows from participantCount', () async {
    final EventParticipantsPage page = await store.fetchParticipants('evt-1');
    final int count = store.findById('evt-1')!.participantCount;
    expect(page.items, hasLength(count));
    expect(page.hasMore, isFalse);
    final EventParticipantsPage second =
        await store.fetchParticipants('evt-1', cursor: 'opaque');
    expect(second.items, isEmpty);
  });
}
