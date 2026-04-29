import 'dart:convert';

import 'package:chisto_mobile/features/home/data/sites_local_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('SitesLocalCache.decodePersistedFeedStore', () {
    test('returns empty map for null, empty, invalid JSON, or non-map', () {
      final SitesLocalCache cache = SitesLocalCache();
      expect(cache.decodePersistedFeedStore(null), isEmpty);
      expect(cache.decodePersistedFeedStore(''), isEmpty);
      expect(cache.decodePersistedFeedStore('not-json'), isEmpty);
      expect(cache.decodePersistedFeedStore('[]'), isEmpty);
    });

    test('decodes valid persisted wrapper', () {
      final SitesLocalCache cache = SitesLocalCache();
      final Map<String, dynamic> decoded = cache.decodePersistedFeedStore(
        jsonEncode(<String, dynamic>{
          'version': 2,
          'feeds': <String, dynamic>{
            'scopeA': <String, dynamic>{
              'updatedAtMs': 1,
              'pages': <dynamic>[],
            },
          },
        }),
      );
      expect(decoded['version'], 2);
      final Map<String, dynamic>? feeds =
          decoded['feeds'] as Map<String, dynamic>?;
      expect(feeds, isNotNull);
      expect(feeds!['scopeA'], isA<Map<String, dynamic>>());
    });
  });

  group('SitesLocalCache persist + load feed', () {
    test('roundtrips a feed page and loads by requestKey', () async {
      final SitesLocalCache cache = SitesLocalCache();
      final DateTime now = DateTime.now();
      const String scopeKey = 's1';
      const String requestKey = 'rk1';
      const Map<String, dynamic> payload = <String, dynamic>{'data': <dynamic>[]};

      await cache.persistFeedSnapshot(
        scopeKey: scopeKey,
        requestKey: requestKey,
        payload: payload,
        now: now,
        page: 1,
        cursor: null,
        nextCursor: 'n1',
      );

      final ({
        Map<String, dynamic> payload,
        DateTime cachedAt,
        int storedPage,
      })? loaded = await cache.loadFeedPage(
        requestKey: requestKey,
        scopeKey: scopeKey,
        page: 1,
      );

      expect(loaded, isNotNull);
      expect(loaded!.payload, payload);
      expect(loaded.storedPage, 1);
      expect(
        loaded.cachedAt.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      );
    });

    test('loadFeedPage returns null when entry is expired', () async {
      final SitesLocalCache cache = SitesLocalCache();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final DateTime old = DateTime.now().subtract(const Duration(hours: 48));
      await prefs.setString(
        SitesLocalCache.feedPersistedCacheKey,
        jsonEncode(<String, dynamic>{
          'version': 2,
          'feeds': <String, dynamic>{
            'expired': <String, dynamic>{
              'updatedAtMs': old.millisecondsSinceEpoch,
              'pages': <dynamic>[
                <String, dynamic>{
                  'requestKey': 'old',
                  'page': 1,
                  'cursor': '',
                  'nextCursor': '',
                  'cachedAtMs': old.millisecondsSinceEpoch,
                  'payload': <String, dynamic>{'data': <dynamic>[]},
                },
              ],
            },
          },
        }),
      );

      final ({
        Map<String, dynamic> payload,
        DateTime cachedAt,
        int storedPage,
      })? loaded = await cache.loadFeedPage(
        requestKey: 'old',
        scopeKey: 'expired',
        page: 1,
      );
      expect(loaded, isNull);
    });
  });

  group('SitesLocalCache map snapshot', () {
    test('roundtrips map payload', () async {
      final SitesLocalCache cache = SitesLocalCache();
      const Map<String, dynamic> payload = <String, dynamic>{
        'data': <dynamic>[],
      };
      await cache.persistMapSnapshot(payload);
      final ({Map<String, dynamic> payload, DateTime cachedAt})? loaded =
          await cache.loadMapSnapshot();
      expect(loaded, isNotNull);
      expect(loaded!.payload, payload);
    });

    test('loadMapSnapshot returns null for expired snapshot', () async {
      final SitesLocalCache cache = SitesLocalCache();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final DateTime old = DateTime.now().subtract(const Duration(hours: 12));
      await prefs.setString(
        SitesLocalCache.mapPersistedCacheKey,
        jsonEncode(<String, dynamic>{
          'cachedAtMs': old.millisecondsSinceEpoch,
          'payload': <String, dynamic>{'data': <dynamic>[]},
        }),
      );
      expect(await cache.loadMapSnapshot(), isNull);
    });

    test('loadMapSnapshot returns null for corrupt JSON', () async {
      final SitesLocalCache cache = SitesLocalCache();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(SitesLocalCache.mapPersistedCacheKey, 'not-json');

      expect(await cache.loadMapSnapshot(), isNull);
    });
  });

  test('clearFeedAndMapSnapshots removes keys', () async {
    final SitesLocalCache cache = SitesLocalCache();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(SitesLocalCache.feedPersistedCacheKey, '{}');
    await prefs.setString(SitesLocalCache.mapPersistedCacheKey, '{}');
    await cache.clearFeedAndMapSnapshots();
    expect(prefs.getString(SitesLocalCache.feedPersistedCacheKey), isNull);
    expect(prefs.getString(SitesLocalCache.mapPersistedCacheKey), isNull);
  });
}
