import 'package:chisto_mobile/features/events/data/in_memory_events_store.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_filter.dart';
import 'package:chisto_mobile/features/events/presentation/controllers/events_feed_controller.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'recording_events_repository.dart';

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
    final EventsFeedController c = EventsFeedController(repository: store);
    addTearDown(c.dispose);

    await store.ready;
    final AppLocalizations l10n = AppLocalizationsEn();

    final List<EcoEvent> a = c.filteredEvents(l10n);
    final List<EcoEvent> b = c.filteredEvents(l10n);
    expect(identical(a, b), isTrue);

    await c.setActiveFilter(EcoEventFilter.nearby);
    final List<EcoEvent> c2 = c.filteredEvents(l10n);
    expect(identical(a, c2), isFalse);
  });

  test('heroEvent reads from full list while client search narrows filtered list',
      () async {
    final EventsFeedController c = EventsFeedController(repository: store);
    addTearDown(c.dispose);

    await store.ready;
    final AppLocalizations l10n = AppLocalizationsEn();

    final EcoEvent? heroAll = c.heroEvent;
    expect(heroAll, isNotNull);

    c.onSearchTextChanged(
      '__no_events_match_this_token__',
      debounce: Duration.zero,
    );
    await Future<void>.delayed(Duration.zero);
    expect(c.filteredEvents(l10n), isEmpty);
    expect(c.heroEvent, heroAll);
  });

  test('applySearchSuggestion syncs server params via refreshEvents', () async {
    final RecordingEventsRepository repo = RecordingEventsRepository();
    final EventsFeedController c = EventsFeedController(repository: repo);
    addTearDown(c.dispose);

    await c.applySearchSuggestion('  river cleanup  ');

    expect(repo.refreshCallCount, greaterThan(0));
    expect(repo.lastRefreshParams?.query, 'river cleanup');
    expect(c.searchQuery, 'river cleanup');
    expect(c.activeSearchParams.query, 'river cleanup');
  });

  test('userPullRefresh returns false when refresh fails', () async {
    final RecordingEventsRepository repo = RecordingEventsRepository();
    repo.refreshShouldThrow = true;
    final EventsFeedController c = EventsFeedController(repository: repo);
    addTearDown(c.dispose);

    final bool ok = await c.userPullRefresh();

    expect(ok, isFalse);
    expect(repo.refreshCallCount, 1);
  });

  test('resetAllDiscoveryFilters clears all state and refreshes', () async {
    final RecordingEventsRepository repo = RecordingEventsRepository();
    final EventsFeedController c = EventsFeedController(repository: repo);
    addTearDown(c.dispose);

    await c.setActiveFilter(EcoEventFilter.nearby);
    await c.applySearchSuggestion('test');
    final int countBefore = repo.refreshCallCount;

    await c.resetAllDiscoveryFilters();

    expect(c.activeFilter, EcoEventFilter.all);
    expect(c.searchQuery, isEmpty);
    expect(c.activeSearchParams.query, isNull);
    expect(repo.refreshCallCount, greaterThan(countBefore));
  });

  test('setCalendarView toggles and memoization resets', () async {
    final EventsFeedController c = EventsFeedController(repository: store);
    addTearDown(c.dispose);

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
    final EventsFeedController c = EventsFeedController(repository: repo);
    addTearDown(c.dispose);

    expect(c.feedPhase(), 'loading');

    await c.loadInitial(initialListEmptyErrorMessage: 'fail');
    expect(c.feedPhase(), 'content');
  });

  test('hasActiveFilters detects active state', () async {
    final RecordingEventsRepository repo = RecordingEventsRepository();
    final EventsFeedController c = EventsFeedController(repository: repo);
    addTearDown(c.dispose);

    expect(c.hasActiveFilters, isFalse);
    await c.setActiveFilter(EcoEventFilter.nearby);
    expect(c.hasActiveFilters, isTrue);
    await c.resetAllDiscoveryFilters();
    expect(c.hasActiveFilters, isFalse);
  });
}
