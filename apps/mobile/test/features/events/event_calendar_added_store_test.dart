import 'package:feature_events/src/data/event_calendar_added_store.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

EcoEvent _event({
  required String id,
  DateTime? start,
  String title = 'Cleanup',
}) {
  final DateTime day = start ?? DateTime(2026, 5, 29, 7, 30);
  return EcoEvent(
    id: id,
    title: title,
    description: '',
    category: EcoEventCategory.generalCleanup,
    siteId: 'site-1',
    siteName: 'Park',
    siteImageUrl: '',
    siteDistanceKm: 1,
    organizerId: 'org-1',
    organizerName: 'Org',
    date: DateTime(day.year, day.month, day.day),
    startTime: EventTime(hour: day.hour, minute: day.minute),
    endTime: const EventTime(hour: 23, minute: 59),
    participantCount: 1,
    status: EcoEventStatus.upcoming,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('isMarkedAdded is false until markAdded', () async {
    final EcoEvent event = _event(id: 'evt-a');
    expect(await EventCalendarAddedStore.isMarkedAdded(event), isFalse);
    await EventCalendarAddedStore.markAdded(event);
    expect(await EventCalendarAddedStore.isMarkedAdded(event), isTrue);
  });

  test('schedule change clears added state for same event id', () async {
    final EcoEvent original = _event(id: 'evt-b');
    await EventCalendarAddedStore.markAdded(original);
    final EcoEvent rescheduled = _event(
      id: 'evt-b',
      start: DateTime(2026, 5, 30, 8, 0),
    );
    expect(await EventCalendarAddedStore.isMarkedAdded(rescheduled), isFalse);
  });

  test('fingerprint differs when title changes', () async {
    final EcoEvent a = _event(id: 'evt-c', title: 'Alpha');
    final EcoEvent b = _event(id: 'evt-c', title: 'Beta');
    await EventCalendarAddedStore.markAdded(a);
    expect(await EventCalendarAddedStore.isMarkedAdded(b), isFalse);
  });
}
