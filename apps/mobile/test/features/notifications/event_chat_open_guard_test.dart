import 'package:chisto_infrastructure/core/providers/events_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:feature_notifications/src/data/event_chat_open_guard.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';
import '../../support/events/in_memory_events_store.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  setUp(() {
    setEventsRepositoryTestOverride(InMemoryEventsStore.instance);
    InMemoryEventsStore.instance.resetToSeed();
    InMemoryEventsStore.instance.loadInitialIfNeeded();
  });

  tearDown(() {
    setEventsRepositoryTestOverride(null);
  });

  group('EventChatOpenGuard', () {
    test('returns true when event is cached', () async {
      final String eventId = InMemoryEventsStore.instance.events.first.id;

      expect(await EventChatOpenGuard.isEventAvailableForChat(eventId), isTrue);
    });

    test('returns false when event is missing after prefetch', () async {
      expect(
        await EventChatOpenGuard.isEventAvailableForChat(
          '550e8400-e29b-41d4-a716-446655440099',
        ),
        isFalse,
      );
    });
  });
}
