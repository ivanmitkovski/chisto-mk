import 'package:chisto_mobile/features/events/domain/models/eco_event_search_params.dart';
import 'package:chisto_mobile/features/events/presentation/controllers/events_search_controller.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scheduleTextSearch debounces then runs search and reaches ready', () async {
    FakeAsync().run((FakeAsync async) {
      EcoEventSearchParams? lastParams;
      final EventsSearchController c = EventsSearchController(
        runSearchParams: (EcoEventSearchParams next) async {
          lastParams = next;
          return true;
        },
      );

      final List<EventsSearchRemotePhase> phases = <EventsSearchRemotePhase>[];
      void onListen() => phases.add(c.phase);

      c.addListener(onListen);

      c.scheduleTextSearch(
        rawText: '  river  ',
        mergedBase: const EcoEventSearchParams(),
        debounce: const Duration(milliseconds: 400),
      );

      expect(c.phase, EventsSearchRemotePhase.idle);

      async.elapse(const Duration(milliseconds: 399));
      expect(lastParams, isNull);

      async.elapse(const Duration(milliseconds: 2));
      expect(lastParams?.query, 'river');
      expect(c.phase, EventsSearchRemotePhase.ready);

      c.removeListener(onListen);
      c.dispose();
    });
  });

  test('empty query after debounce clears query and ends idle', () async {
    FakeAsync().run((FakeAsync async) {
      int calls = 0;
      final EventsSearchController c = EventsSearchController(
        runSearchParams: (EcoEventSearchParams next) async {
          calls++;
          expect(next.query, isNull);
          return true;
        },
      );

      c.scheduleTextSearch(
        rawText: '   ',
        mergedBase: const EcoEventSearchParams(query: 'x'),
        debounce: const Duration(milliseconds: 100),
      );

      async.elapse(const Duration(milliseconds: 100));
      expect(calls, 1);
      expect(c.phase, EventsSearchRemotePhase.idle);

      c.dispose();
    });
  });

  test('cancel clears pending timer', () async {
    FakeAsync().run((FakeAsync async) {
      int calls = 0;
      final EventsSearchController c = EventsSearchController(
        runSearchParams: (_) async {
          calls++;
          return true;
        },
      );

      c.scheduleTextSearch(
        rawText: 'a',
        mergedBase: const EcoEventSearchParams(),
        debounce: const Duration(milliseconds: 200),
      );
      c.cancel();
      async.elapse(const Duration(seconds: 1));
      expect(calls, 0);

      c.dispose();
    });
  });
}
