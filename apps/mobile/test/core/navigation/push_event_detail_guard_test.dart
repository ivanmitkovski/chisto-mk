import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:chisto_infrastructure/core/navigation/event_detail_navigation_guard.dart';
import 'package:chisto_infrastructure/core/providers/events_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';
import '../../support/events/in_memory_events_store.dart';

const String _eventId = '550e8400-e29b-41d4-a716-446655440000';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  setUp(() {
    EventDetailNavigationGuard.resetForTest();
    setEventsRepositoryTestOverride(InMemoryEventsStore.instance);
    InMemoryEventsStore.instance.resetToSeed();
    InMemoryEventsStore.instance.loadInitialIfNeeded();
  });

  tearDown(() {
    setEventsRepositoryTestOverride(null);
  });

  group('EventDetailNavigationGuard.eventDetailPath', () {
    test('builds canonical detail path', () {
      expect(
        EventDetailNavigationGuard.eventDetailPath('evt-1'),
        '${AppRoutes.eventsDetail}/evt-1',
      );
    });
  });

  group('EventDetailNavigationGuard.coalescedPush', () {
    test('coalesces concurrent pushes for the same event id', () async {
      int pushCount = 0;

      Future<void> push() async {
        pushCount++;
        await Future<void>.delayed(const Duration(milliseconds: 30));
      }

      final Future<void> first =
          EventDetailNavigationGuard.coalescedPush('evt-1', push);
      final Future<void> second =
          EventDetailNavigationGuard.coalescedPush('evt-1', push);

      expect(identical(first, second), isTrue);
      await Future.wait(<Future<void>>[first, second]);
      expect(pushCount, 1);
    });

    test('allows a second push after the first completes', () async {
      int pushCount = 0;

      await EventDetailNavigationGuard.coalescedPush('evt-2', () async {
        pushCount++;
      });
      await EventDetailNavigationGuard.coalescedPush('evt-2', () async {
        pushCount++;
      });

      expect(pushCount, 2);
    });

    test('does not coalesce pushes for different event ids', () async {
      int pushCount = 0;

      final Future<void> first = EventDetailNavigationGuard.coalescedPush(
        'evt-a',
        () async {
          pushCount++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
        },
      );
      final Future<void> second = EventDetailNavigationGuard.coalescedPush(
        'evt-b',
        () async {
          pushCount++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
        },
      );

      expect(identical(first, second), isFalse);
      await Future.wait(<Future<void>>[first, second]);
      expect(pushCount, 2);
    });

    test('empty event id is a no-op', () async {
      int pushCount = 0;
      await EventDetailNavigationGuard.coalescedPush('  ', () async {
        pushCount++;
      });
      expect(pushCount, 0);
    });
  });

  testWidgets('isEventDetailTopRoute is true on detail location', (
    WidgetTester tester,
  ) async {
    await pumpAppRouter(
      tester,
      initialLocation: EventDetailNavigationGuard.eventDetailPath(_eventId),
    );
    await tester.pump();
    await tester.pump();

    expect(EventDetailNavigationGuard.isEventDetailTopRoute(_eventId), isTrue);
    expect(EventDetailNavigationGuard.isEventDetailTopRoute('other-id'), isFalse);
  });

  testWidgets('coalescedPush skips when detail is already top route', (
    WidgetTester tester,
  ) async {
    await pumpAppRouter(
      tester,
      initialLocation: EventDetailNavigationGuard.eventDetailPath(_eventId),
    );
    await tester.pump();
    await tester.pump();

    int pushCount = 0;
    await EventDetailNavigationGuard.coalescedPush(_eventId, () async {
      pushCount++;
    });

    expect(pushCount, 0);
  });

}
