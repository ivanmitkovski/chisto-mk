import 'package:fake_async/fake_async.dart';
import 'package:feature_events/src/domain/models/eco_event_search_params.dart';
import 'package:feature_events/src/presentation/controllers/events_feed_controller.dart';
import 'package:feature_events/src/presentation/controllers/events_feed_state.dart';
import 'package:feature_events/src/presentation/controllers/events_search_controller.dart';
import 'package:feature_events/src/presentation/controllers/events_search_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'scheduleTextSearch debounces then runs search and reaches ready',
    () async {
      FakeAsync().run((FakeAsync async) {
        EcoEventSearchParams? lastParams;
        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            eventsFeedControllerProvider.overrideWith(() {
              return _StubEventsFeedController(
                onSetSearchParams: (EcoEventSearchParams p) async {
                  lastParams = p;
                  return true;
                },
              );
            }),
          ],
        );
        addTearDown(container.dispose);
        final EventsSearchController c = container.read(
          eventsSearchControllerProvider.notifier,
        );

        final List<EventsSearchRemotePhase> phases =
            <EventsSearchRemotePhase>[];
        container.listen(eventsSearchControllerProvider, (
          EventsSearchState? _,
          EventsSearchState next,
        ) {
          phases.add(next.phase);
        });

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
      });
    },
  );

  test('empty query after debounce clears query and ends idle', () async {
    FakeAsync().run((FakeAsync async) {
      int calls = 0;
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          eventsFeedControllerProvider.overrideWith(() {
            return _StubEventsFeedController(
              onSetSearchParams: (EcoEventSearchParams next) async {
                calls++;
                expect(next.query, isNull);
                return true;
              },
            );
          }),
        ],
      );
      addTearDown(container.dispose);
      final EventsSearchController c = container.read(
        eventsSearchControllerProvider.notifier,
      );

      c.scheduleTextSearch(
        rawText: '   ',
        mergedBase: const EcoEventSearchParams(query: 'x'),
        debounce: const Duration(milliseconds: 100),
      );

      async.elapse(const Duration(milliseconds: 100));
      expect(calls, 1);
      expect(c.phase, EventsSearchRemotePhase.idle);
    });
  });

  test('cancel clears pending timer', () async {
    FakeAsync().run((FakeAsync async) {
      int calls = 0;
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          eventsFeedControllerProvider.overrideWith(() {
            return _StubEventsFeedController(
              onSetSearchParams: (_) async {
                calls++;
                return true;
              },
            );
          }),
        ],
      );
      addTearDown(container.dispose);
      final EventsSearchController c = container.read(
        eventsSearchControllerProvider.notifier,
      );

      c.scheduleTextSearch(
        rawText: 'a',
        mergedBase: const EcoEventSearchParams(),
        debounce: const Duration(milliseconds: 200),
      );
      c.cancel();
      async.elapse(const Duration(seconds: 1));
      expect(calls, 0);
    });
  });
}

class _StubEventsFeedController extends EventsFeedController {
  _StubEventsFeedController({required this.onSetSearchParams});

  final Future<bool> Function(EcoEventSearchParams next) onSetSearchParams;

  @override
  EventsFeedState build() => const EventsFeedState(isInitialLoading: false);

  @override
  Future<bool> setSearchParams(EcoEventSearchParams next) =>
      onSetSearchParams(next);
}
