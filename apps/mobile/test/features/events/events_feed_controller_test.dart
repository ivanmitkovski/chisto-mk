import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/l10n/app_localizations_en.dart';
import 'package:feature_events/src/application/events_providers.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/domain/models/eco_event_filter.dart';
import 'package:feature_events/src/domain/repositories/events_repository.dart';
import 'package:feature_events/src/presentation/controllers/events_feed_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/events/in_memory_events_store.dart';
import 'recording_events_repository.dart';

EventsFeedController _feedController(ProviderContainer container) =>
    container.read(eventsFeedControllerProvider.notifier);

ProviderContainer _feedContainer(EventsRepository repo) {
  setEventsRepositoryTestOverride(repo);
  final ProviderContainer container = ProviderContainer();
  addTearDown(() {
    container.dispose();
    setEventsRepositoryTestOverride(null);
  });
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryEventsStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store = InMemoryEventsStore.instance;
    store.resetToSeed();
    store.loadInitialIfNeeded();
  });

  test('filteredEvents is memoized for stable inputs', () async {
    final ProviderContainer container = _feedContainer(store);
    final EventsFeedController c = _feedController(container);

    await store.ready;
    final AppLocalizations l10n = AppLocalizationsEn();

    final List<EcoEvent> a = c.filteredEvents(l10n);
    final List<EcoEvent> b = c.filteredEvents(l10n);
    expect(identical(a, b), isTrue);

    await c.setActiveFilter(EcoEventFilter.nearby);
    final List<EcoEvent> c2 = c.filteredEvents(l10n);
    expect(identical(a, c2), isFalse);
  });

  test('filteredEvents does not apply client-side text filter', () async {
    final ProviderContainer container = _feedContainer(store);
    final EventsFeedController c = _feedController(container);

    await store.ready;
    final AppLocalizations l10n = AppLocalizationsEn();
    final int countBefore = c.filteredEvents(l10n).length;

    c.onSearchTextChanged(
      '__no_events_match_this_token__',
      debounce: Duration.zero,
    );
    await Future<void>.delayed(Duration.zero);
    expect(c.filteredEvents(l10n).length, countBefore);
  });

  test('applySearchSuggestion syncs server params via refreshEvents', () async {
    final RecordingEventsRepository repo = RecordingEventsRepository();
    final ProviderContainer container = _feedContainer(repo);
    final EventsFeedController c = _feedController(container);

    await c.applySearchSuggestion('  river cleanup  ');

    expect(repo.refreshCallCount, greaterThan(0));
    expect(repo.lastRefreshParams?.query, 'river cleanup');
    expect(c.searchQuery, 'river cleanup');
    expect(c.activeSearchParams.query, 'river cleanup');
  });

  test('userPullRefresh returns false when refresh fails', () async {
    final RecordingEventsRepository repo = RecordingEventsRepository();
    repo.refreshShouldThrow = true;
    final ProviderContainer container = _feedContainer(repo);
    final EventsFeedController c = _feedController(container);

    final bool ok = await c.userPullRefresh();

    expect(ok, isFalse);
    expect(repo.refreshCallCount, 1);
    expect(c.lastPullRefreshError, isNotNull);
    expect(c.lastPullRefreshError!.code, 'NETWORK_ERROR');
  });

  test('resetAllDiscoveryFilters clears all state and refreshes', () async {
    final RecordingEventsRepository repo = RecordingEventsRepository();
    final ProviderContainer container = _feedContainer(repo);
    final EventsFeedController c = _feedController(container);

    await c.setActiveFilter(EcoEventFilter.nearby);
    await c.applySearchSuggestion('test');
    final int countBefore = repo.refreshCallCount;

    await c.resetAllDiscoveryFilters();

    expect(c.activeFilter, EcoEventFilter.all);
    expect(c.searchQuery, isEmpty);
    expect(c.activeSearchParams.query, isNull);
    expect(repo.refreshCallCount, greaterThan(countBefore));
  });

  test('setActiveFilter nearby switches instantly without refreshEvents', () async {
    final RecordingEventsRepository repo = RecordingEventsRepository();
    final ProviderContainer container = _feedContainer(repo);
    final EventsFeedController c = _feedController(container);

    final bool ok = await c.setActiveFilter(EcoEventFilter.nearby);

    expect(ok, isTrue);
    expect(c.activeFilter, EcoEventFilter.nearby);
    expect(repo.refreshCallCount, 0);
  });

  test('setActiveFilter past triggers refreshEvents for server lifecycle', () async {
    final RecordingEventsRepository repo = RecordingEventsRepository();
    final ProviderContainer container = _feedContainer(repo);
    final EventsFeedController c = _feedController(container);

    final int before = repo.refreshCallCount;
    final bool ok = await c.setActiveFilter(EcoEventFilter.past);

    expect(ok, isTrue);
    expect(c.activeFilter, EcoEventFilter.past);
    expect(repo.refreshCallCount, before + 1);
    expect(
      repo.lastRefreshParams?.statuses,
      <EcoEventStatus>{
        EcoEventStatus.completed,
        EcoEventStatus.cancelled,
      },
    );
  });

  test('setCalendarView toggles and memoization resets', () async {
    final ProviderContainer container = _feedContainer(store);
    final EventsFeedController c = _feedController(container);

    expect(c.calendarView, isFalse);
    c.setCalendarView(true);
    expect(c.calendarView, isTrue);
    c.setCalendarView(true);
    expect(c.calendarView, isTrue);
    c.setCalendarView(false);
    expect(c.calendarView, isFalse);
  });

  test('feedPhase returns loading, error, content correctly', () async {
    final RecordingEventsRepository repo = RecordingEventsRepository();
    final ProviderContainer container = _feedContainer(repo);
    final EventsFeedController c = _feedController(container);

    expect(c.feedPhase(), 'loading');

    await c.loadInitial(initialListEmptyErrorMessage: 'fail');
    expect(c.feedPhase(), 'content');
  });

  test('hasActiveFilters detects active state', () async {
    final RecordingEventsRepository repo = RecordingEventsRepository();
    final ProviderContainer container = _feedContainer(repo);
    final EventsFeedController c = _feedController(container);

    expect(c.hasActiveFilters, isFalse);
    await c.setActiveFilter(EcoEventFilter.nearby);
    expect(c.hasActiveFilters, isTrue);
    await c.resetAllDiscoveryFilters();
    expect(c.hasActiveFilters, isFalse);
  });

  test('setUserLocationHint invalidates nearby memoization', () async {
    final ProviderContainer container = _feedContainer(store);
    final EventsFeedController c = _feedController(container);

    await store.ready;
    final AppLocalizations l10n = AppLocalizationsEn();

    await c.setActiveFilter(EcoEventFilter.nearby);
    final List<EcoEvent> before = c.filteredEvents(l10n);

    c.setUserLocationHint(latitude: 41.9981, longitude: 21.4254);
    final List<EcoEvent> after = c.filteredEvents(l10n);

    expect(identical(before, after), isFalse);
  });
}
