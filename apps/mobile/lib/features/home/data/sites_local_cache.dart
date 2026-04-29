import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Disk persistence for offline feed pages and last map snapshot (SharedPreferences).
class SitesLocalCache {
  SitesLocalCache();

  static const String feedPersistedCacheKey = 'feed_cache_pages_v2';
  static const String mapPersistedCacheKey = 'map_sites_snapshot_v1';
  static const Duration feedPersistedCacheTtl = Duration(hours: 24);
  static const Duration mapPersistedCacheTtl = Duration(hours: 6);
  static const int maxPersistedFeeds = 8;
  static const int maxPersistedPagesPerFeed = 6;

  Map<String, dynamic> decodePersistedFeedStore(String? raw) {
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return <String, dynamic>{};
      return decoded;
    } on FormatException {
      return <String, dynamic>{};
    }
  }

  Future<void> persistFeedSnapshot({
    required String scopeKey,
    required String requestKey,
    required Map<String, dynamic> payload,
    required DateTime now,
    required int page,
    required String? cursor,
    required String? nextCursor,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> decoded = decodePersistedFeedStore(
      prefs.getString(feedPersistedCacheKey),
    );
    final Map<String, dynamic> feeds =
        (decoded['feeds'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> scope =
        (feeds[scopeKey] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final List<dynamic> existingPages =
        (scope['pages'] as List<dynamic>?) ?? <dynamic>[];

    final List<Map<String, dynamic>> pages = existingPages
        .whereType<Map<String, dynamic>>()
        .where((Map<String, dynamic> entry) {
          final int cachedAtMs = (entry['cachedAtMs'] as num?)?.toInt() ?? 0;
          if (cachedAtMs <= 0) return false;
          final DateTime cachedAt = DateTime.fromMillisecondsSinceEpoch(
            cachedAtMs,
          );
          return now.difference(cachedAt) <= feedPersistedCacheTtl;
        })
        .toList();

    if ((cursor == null || cursor.isEmpty) && page == 1) {
      pages.clear();
    }
    pages.removeWhere(
      (Map<String, dynamic> entry) =>
          (entry['requestKey'] as String?) == requestKey,
    );
    pages.add(<String, dynamic>{
      'requestKey': requestKey,
      'page': page,
      'cursor': cursor ?? '',
      'nextCursor': nextCursor ?? '',
      'cachedAtMs': now.millisecondsSinceEpoch,
      'payload': payload,
    });
    pages.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final int pageA = (a['page'] as num?)?.toInt() ?? 1;
      final int pageB = (b['page'] as num?)?.toInt() ?? 1;
      return pageA.compareTo(pageB);
    });
    if (pages.length > maxPersistedPagesPerFeed) {
      pages.removeRange(0, pages.length - maxPersistedPagesPerFeed);
    }

    feeds[scopeKey] = <String, dynamic>{
      'updatedAtMs': now.millisecondsSinceEpoch,
      'pages': pages,
    };
    if (feeds.length > maxPersistedFeeds) {
      final List<MapEntry<String, dynamic>> entries = feeds.entries.toList()
        ..sort((MapEntry<String, dynamic> a, MapEntry<String, dynamic> b) {
          final int aMs =
              ((a.value as Map<String, dynamic>?)?['updatedAtMs'] as num?)
                  ?.toInt() ??
              0;
          final int bMs =
              ((b.value as Map<String, dynamic>?)?['updatedAtMs'] as num?)
                  ?.toInt() ??
              0;
          return bMs.compareTo(aMs);
        });
      final Set<String> allowed = entries
          .take(maxPersistedFeeds)
          .map((MapEntry<String, dynamic> e) => e.key)
          .toSet();
      feeds.removeWhere((String key, dynamic value) => !allowed.contains(key));
    }

    final Map<String, dynamic> wrapper = <String, dynamic>{
      'version': 2,
      'feeds': feeds,
    };
    await prefs.setString(feedPersistedCacheKey, jsonEncode(wrapper));
  }

  Future<
      ({
        Map<String, dynamic> payload,
        DateTime cachedAt,
        int storedPage,
      })?> loadFeedPage({
    required String requestKey,
    required String scopeKey,
    required int page,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> decoded = decodePersistedFeedStore(
      prefs.getString(feedPersistedCacheKey),
    );
    final Map<String, dynamic> feeds =
        (decoded['feeds'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final Map<String, dynamic>? scope =
        feeds[scopeKey] as Map<String, dynamic>?;
    if (scope == null) return null;
    final List<dynamic> pages =
        (scope['pages'] as List<dynamic>?) ?? const <dynamic>[];

    Map<String, dynamic>? selected = pages
        .whereType<Map<String, dynamic>>()
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (Map<String, dynamic>? entry) =>
              (entry?['requestKey'] as String?) == requestKey,
          orElse: () => null,
        );
    selected ??= pages
        .whereType<Map<String, dynamic>>()
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (Map<String, dynamic>? entry) =>
              ((entry?['page'] as num?)?.toInt() ?? -1) == page,
          orElse: () => null,
        );
    if (selected == null) return null;

    final int cachedAtMs = (selected['cachedAtMs'] as num?)?.toInt() ?? 0;
    if (cachedAtMs <= 0) return null;
    final DateTime cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMs);
    if (DateTime.now().difference(cachedAt) > feedPersistedCacheTtl) {
      return null;
    }

    final dynamic payload = selected['payload'];
    if (payload is! Map<String, dynamic>) return null;
    final int storedPage = ((selected['page'] as num?)?.toInt() ?? page)
        .clamp(1, 999999);
    return (payload: payload, cachedAt: cachedAt, storedPage: storedPage);
  }

  Future<void> persistMapSnapshot(Map<String, dynamic> payload) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> wrapper = <String, dynamic>{
      'cachedAtMs': DateTime.now().millisecondsSinceEpoch,
      'payload': payload,
    };
    await prefs.setString(mapPersistedCacheKey, jsonEncode(wrapper));
  }

  Future<({Map<String, dynamic> payload, DateTime cachedAt})?> loadMapSnapshot() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(mapPersistedCacheKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final int cachedAtMs = (decoded['cachedAtMs'] as num?)?.toInt() ?? 0;
    if (cachedAtMs <= 0) {
      return null;
    }
    final DateTime cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMs);
    if (DateTime.now().difference(cachedAt) > mapPersistedCacheTtl) {
      return null;
    }
    final Object? payload = decoded['payload'];
    if (payload is! Map<String, dynamic>) {
      return null;
    }
    return (payload: payload, cachedAt: cachedAt);
  }

  Future<void> clearFeedAndMapSnapshots() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(feedPersistedCacheKey);
    await prefs.remove(mapPersistedCacheKey);
  }
}
