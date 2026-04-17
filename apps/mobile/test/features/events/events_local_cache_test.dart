import 'dart:convert';

import 'package:chisto_mobile/features/events/data/events_local_cache.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_search_params.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

EcoEvent _minimalEvent({required String id}) {
  return EcoEvent(
    id: id,
    title: 'T',
    description: 'D',
    category: EcoEventCategory.generalCleanup,
    siteId: 's',
    siteName: 'Site',
    siteImageUrl: '',
    siteDistanceKm: 1,
    organizerId: 'o',
    organizerName: 'Org',
    date: DateTime.utc(2026, 4, 16),
    startTime: const EventTime(hour: 9, minute: 0),
    endTime: const EventTime(hour: 10, minute: 0),
    participantCount: 0,
    status: EcoEventStatus.upcoming,
    createdAt: DateTime.utc(2026, 4, 1),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('storageKeyForListParams uses legacy key when params null or empty', () {
    expect(EventsLocalCache.storageKeyForListParams(null), EventsLocalCache.legacyEventsCacheKey);
    expect(
      EventsLocalCache.storageKeyForListParams(const EcoEventSearchParams()),
      EventsLocalCache.legacyEventsCacheKey,
    );
  });

  test('storageKeyForListParams namespaces non-empty params', () {
    final EcoEventSearchParams p = EcoEventSearchParams(
      query: 'x',
      categories: <EcoEventCategory>{EcoEventCategory.riverAndLake},
    );
    final String key = EventsLocalCache.storageKeyForListParams(p);
    expect(key, startsWith('${EventsLocalCache.legacyEventsCacheKey}_'));
    expect(key, isNot(equals(EventsLocalCache.legacyEventsCacheKey)));
  });

  test('writeEvents and readEvents round-trip per params key', () async {
    const EventsLocalCache cache = EventsLocalCache();
    final EcoEventSearchParams filtered = EcoEventSearchParams(
      query: 'q',
      statuses: <EcoEventStatus>{EcoEventStatus.upcoming},
    );
    final List<EcoEvent> globalList = <EcoEvent>[_minimalEvent(id: 'g1')];
    final List<EcoEvent> filteredList = <EcoEvent>[_minimalEvent(id: 'f1')];

    await cache.writeEvents(globalList, forActiveListParams: null);
    await cache.writeEvents(filteredList, forActiveListParams: filtered);

    final List<EcoEvent>? readGlobal = await cache.readEvents(forActiveListParams: null);
    final List<EcoEvent>? readFiltered =
        await cache.readEvents(forActiveListParams: filtered);

    expect(readGlobal?.single.id, 'g1');
    expect(readFiltered?.single.id, 'f1');
  });

  test('clear removes legacy and filtered keys', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    const EventsLocalCache cache = EventsLocalCache();
    final EcoEventSearchParams filtered = const EcoEventSearchParams(query: 'z');

    await prefs.setString(
      EventsLocalCache.legacyEventsCacheKey,
      jsonEncode(<Map<String, dynamic>>[_minimalEvent(id: 'a').toJson()]),
    );
    await prefs.setString(
      EventsLocalCache.storageKeyForListParams(filtered),
      jsonEncode(<Map<String, dynamic>>[_minimalEvent(id: 'b').toJson()]),
    );

    await cache.clear();

    expect(prefs.getString(EventsLocalCache.legacyEventsCacheKey), isNull);
    expect(prefs.getString(EventsLocalCache.storageKeyForListParams(filtered)), isNull);
  });
}
