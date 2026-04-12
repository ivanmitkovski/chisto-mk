import 'package:chisto_mobile/features/events/data/in_memory_events_store.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_filter.dart';
import 'package:chisto_mobile/features/events/presentation/controllers/events_feed_controller.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}
