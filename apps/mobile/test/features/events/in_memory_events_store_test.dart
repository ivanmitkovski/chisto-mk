import 'package:chisto_mobile/features/events/data/in_memory_events_store.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late InMemoryEventsStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store = InMemoryEventsStore.instance;
    store.resetToSeed();
  });

  test('enforces lifecycle transitions', () {
    final EcoEvent? initial = store.findById('evt-1');
    expect(initial, isNotNull);
    expect(initial!.status, equals(EcoEventStatus.upcoming));

    final bool skipToCompleted = store.updateStatus('evt-1', EcoEventStatus.completed);
    expect(skipToCompleted, isFalse);
    expect(store.findById('evt-1')!.status, equals(EcoEventStatus.upcoming));

    final bool start = store.updateStatus('evt-1', EcoEventStatus.inProgress);
    expect(start, isTrue);
    expect(store.findById('evt-1')!.status, equals(EcoEventStatus.inProgress));

    final bool complete = store.updateStatus('evt-1', EcoEventStatus.completed);
    expect(complete, isTrue);
    expect(store.findById('evt-1')!.status, equals(EcoEventStatus.completed));
  });

  test('sets and clears event reminder', () {
    final DateTime at = DateTime(2026, 1, 1, 9, 0);
    final bool enabled = store.setReminder(
      eventId: 'evt-1',
      enabled: true,
      reminderAt: at,
    );
    expect(enabled, isTrue);
    expect(store.findById('evt-1')!.reminderEnabled, isTrue);
    expect(store.findById('evt-1')!.reminderAt, equals(at));

    final bool disabled = store.setReminder(
      eventId: 'evt-1',
      enabled: false,
      reminderAt: null,
    );
    expect(disabled, isTrue);
    expect(store.findById('evt-1')!.reminderEnabled, isFalse);
    expect(store.findById('evt-1')!.reminderAt, isNull);
  });

  test('saves organizer after images', () {
    final bool updated = store.setAfterImages(
      eventId: 'evt-1',
      imagePaths: <String>['/tmp/a.jpg', '/tmp/b.jpg'],
    );
    expect(updated, isTrue);
    expect(store.findById('evt-1')!.afterImagePaths.length, equals(2));

    final bool noOp = store.setAfterImages(
      eventId: 'evt-1',
      imagePaths: <String>['/tmp/a.jpg', '/tmp/b.jpg'],
    );
    expect(noOp, isFalse);
  });
}
