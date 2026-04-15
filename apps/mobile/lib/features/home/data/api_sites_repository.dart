import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/cache/site_image_provider.dart';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/home/domain/models/cleaning_event.dart';
import 'package:chisto_mobile/features/home/domain/models/co_reporter_profile.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/models/site_report.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

const ImageProvider _placeholderImage = AssetImage(
  'assets/images/content/people_cleaning.png',
);

bool _jsonTruthy(Object? value) {
  if (value == true) return true;
  if (value == false || value == null) return false;
  if (value is num) return value != 0;
  if (value is String) {
    final String t = value.trim().toLowerCase();
    return t == 'true' || t == '1' || t == 'yes';
  }
  return false;
}

bool _jsonBoolField(Map<String, dynamic> json, String camel, String snake) {
  return _jsonTruthy(json[camel]) || _jsonTruthy(json[snake]);
}

/// POST/DELETE engagement endpoints may return a bare object or `{ "data": { ... } }`.
Map<String, dynamic>? _engagementSnapshotJsonRoot(Map<String, dynamic>? json) {
  if (json == null) return null;
  final Object? data = json['data'];
  if (data is Map<String, dynamic>) {
    if (data.containsKey('upvotesCount') ||
        data.containsKey('isUpvotedByMe') ||
        data.containsKey('is_upvoted_by_me')) {
      return data;
    }
  }
  return json;
}

/// Matches [SiteReport.reporterName] when the API omits a display name.
const String _anonymousCoReporterName = 'Anonymous';

String _coReporterDisplayName(Map<String, dynamic>? user) {
  if (user == null) {
    return _anonymousCoReporterName;
  }
  final String fn =
      '${user['firstName'] ?? user['first_name'] ?? ''}'.trim();
  final String ln =
      '${user['lastName'] ?? user['last_name'] ?? ''}'.trim();
  final String name = '$fn $ln'.trim();
  return name.isEmpty ? _anonymousCoReporterName : name;
}

String _preferRicherCoReporterName(String existing, String incoming) {
  if (existing == _anonymousCoReporterName &&
      incoming != _anonymousCoReporterName) {
    return incoming;
  }
  if (incoming == _anonymousCoReporterName &&
      existing != _anonymousCoReporterName) {
    return existing;
  }
  return existing;
}

String? _preferNonEmptyString(String? a, String? b) {
  final String? x = a?.trim();
  final String? y = b?.trim();
  if (x != null && x.isNotEmpty) {
    return x;
  }
  if (y != null && y.isNotEmpty) {
    return y;
  }
  return null;
}

/// Some gateways or older clients wrap entities as `{ "data": <site> }`.
Map<String, dynamic> _siteEntityJsonRoot(Map<String, dynamic> json) {
  final Object? directReports = json['reports'];
  if (directReports is List<dynamic>) {
    return json;
  }
  final Object? data = json['data'];
  if (data is Map<String, dynamic>) {
    final Object? dr = data['reports'];
    if (dr is List<dynamic>) {
      return data;
    }
    final Object? site = data['site'];
    if (site is Map<String, dynamic>) {
      final Object? sr = site['reports'];
      if (sr is List<dynamic>) {
        return site;
      }
    }
    // GET /sites/:id wrapped as `{ "data": <site> }` without a top-level `reports` array on the root.
    if (data['id'] is String &&
        (data.containsKey('latitude') ||
            data.containsKey('longitude') ||
            data.containsKey('upvotesCount'))) {
      return data;
    }
  }
  return json;
}

Map<String, dynamic>? _jsonObjectToStringKeyedMap(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    final Map<String, dynamic> out = <String, dynamic>{};
    for (final MapEntry<dynamic, dynamic> e in raw.entries) {
      out[e.key.toString()] = e.value;
    }
    return out;
  }
  return null;
}

List<Map<String, dynamic>> _mapListOfObjects(List<dynamic> raw) {
  final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
  for (final dynamic item in raw) {
    final Map<String, dynamic>? m = _jsonObjectToStringKeyedMap(item);
    if (m != null) {
      out.add(m);
    }
  }
  return out;
}

List<dynamic> _reportCoReportersList(Map<String, dynamic> r) {
  final Object? v = r['coReporters'] ?? r['co_reporters'];
  if (v is List<dynamic>) {
    return v;
  }
  return <dynamic>[];
}

List<dynamic> _reportMediaUrlsList(Map<String, dynamic> r) {
  final Object? v = r['mediaUrls'] ?? r['media_urls'];
  if (v is List<dynamic>) {
    return v;
  }
  return <dynamic>[];
}

String? _coReporterRowUserId(Map<String, dynamic> co) {
  final Object? v = co['userId'] ?? co['user_id'];
  if (v is String) {
    final String t = v.trim();
    return t.isEmpty ? null : t;
  }
  if (v is num) {
    return v.toString();
  }
  return null;
}

Map<String, dynamic>? _coReporterRowUser(Map<String, dynamic> co) {
  final Object? u = co['user'] ?? co['User'];
  return _jsonObjectToStringKeyedMap(u);
}

DateTime? _coReporterRowReportedAt(Map<String, dynamic> co) {
  final Object? raw = co['reportedAt'] ?? co['reported_at'];
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw);
  }
  return null;
}

/// GET /sites/:id may include a top-level `coReporterNames` array from the API.
List<String> _siteDetailCoReporterNamesFromApiField(Object? raw) {
  if (raw is! List<dynamic>) {
    return <String>[];
  }
  final List<String> out = <String>[];
  for (final dynamic e in raw) {
    if (e is String) {
      final String t = e.trim();
      if (t.isNotEmpty) {
        out.add(t);
      }
    } else if (e != null) {
      final String t = e.toString().trim();
      if (t.isNotEmpty) {
        out.add(t);
      }
    }
  }
  return out;
}

List<CoReporterProfile> _coReporterSummariesFromApiField(Object? raw) {
  if (raw is! List<dynamic>) {
    return <CoReporterProfile>[];
  }
  final List<CoReporterProfile> out = <CoReporterProfile>[];
  for (final dynamic item in raw) {
    final Map<String, dynamic>? m = _jsonObjectToStringKeyedMap(item);
    if (m == null) continue;
    final String name = '${m['name'] ?? m['displayName'] ?? ''}'.trim();
    if (name.isEmpty) continue;
    final Object? av = m['avatarUrl'] ?? m['avatar_url'];
    final String? avatarUrl =
        av is String && av.trim().isNotEmpty ? av.trim() : null;
    final String? userId = _coReporterRowUserId(m);
    out.add(
      CoReporterProfile(
        displayName: name,
        avatarUrl: avatarUrl,
        userId: userId,
      ),
    );
  }
  return out;
}

class ApiSitesRepository implements SitesRepository {
  ApiSitesRepository({
    required ApiClient client,
    AuthState? authState,
  })  : _client = client,
        _authState = authState;

  final ApiClient _client;
  final AuthState? _authState;
  static const Duration _feedCacheTtl = Duration(seconds: 20);
  static const Duration _feedPersistedCacheTtl = Duration(hours: 24);
  static const String _feedPersistedCacheKey = 'feed_cache_pages_v2';
  static const String _mapPersistedCacheKey = 'map_sites_snapshot_v1';
  static const Duration _mapPersistedCacheTtl = Duration(hours: 6);
  static const int _maxPersistedFeeds = 8;
  static const int _maxPersistedPagesPerFeed = 6;
  static const String _localUpvoteIdsPrefix = 'site_upvote_ids_';
  static const int _localUpvoteIdsMax = 400;
  final Map<String, ({SitesListResult result, DateTime cachedAt})>
  _memoryFeedCache = <String, ({SitesListResult result, DateTime cachedAt})>{};

  Future<Set<String>> _readLocalUpvoteIds() async {
    final String? uid = _authState?.userId;
    if (uid == null || uid.isEmpty) {
      return <String>{};
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw =
        prefs.getString('$_localUpvoteIdsPrefix$uid') ?? '';
    if (raw.isEmpty) {
      return <String>{};
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        return <String>{};
      }
      final Set<String> out = <String>{};
      for (final Object? e in decoded) {
        if (e is String && e.isNotEmpty) {
          out.add(e);
        }
      }
      return out;
    } on FormatException {
      return <String>{};
    }
  }

  Future<void> _writeLocalUpvoteIds(Set<String> ids) async {
    final String? uid = _authState?.userId;
    if (uid == null || uid.isEmpty) {
      return;
    }
    final List<String> list = ids.toList();
    if (list.length > _localUpvoteIdsMax) {
      list.removeRange(0, list.length - _localUpvoteIdsMax);
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_localUpvoteIdsPrefix$uid',
      jsonEncode(list),
    );
  }

  Future<void> _rememberLocalUpvote(String siteId) async {
    if (siteId.isEmpty) {
      return;
    }
    final Set<String> ids = Set<String>.from(await _readLocalUpvoteIds());
    if (ids.add(siteId)) {
      await _writeLocalUpvoteIds(ids);
    }
  }

  Future<void> _forgetLocalUpvote(String siteId) async {
    if (siteId.isEmpty) {
      return;
    }
    final Set<String> ids = Set<String>.from(await _readLocalUpvoteIds());
    if (ids.remove(siteId)) {
      await _writeLocalUpvoteIds(ids);
    }
  }

  /// Merges server `isUpvotedByMe` with locally remembered upvotes so the UI stays
  /// correct across feed reloads, cold cache, or responses without personalization.
  Future<List<PollutionSite>> _applyLocalUpvotePersistence(
    List<PollutionSite> sites,
  ) async {
    final String? uid = _authState?.userId;
    if (uid == null || uid.isEmpty || sites.isEmpty) {
      return sites;
    }
    final Set<String> local = Set<String>.from(await _readLocalUpvoteIds());
    bool changed = false;
    final List<PollutionSite> out = <PollutionSite>[];
    for (final PollutionSite s in sites) {
      if (s.isUpvotedByMe && local.add(s.id)) {
        changed = true;
      }
      final bool merged = s.isUpvotedByMe || local.contains(s.id);
      out.add(
        merged == s.isUpvotedByMe ? s : s.copyWith(isUpvotedByMe: merged),
      );
    }
    if (changed) {
      await _writeLocalUpvoteIds(local);
    }
    return out;
  }

  Future<SitesListResult> _mergeUpvotesIntoSitesList(SitesListResult result) async {
    final List<PollutionSite> sites =
        await _applyLocalUpvotePersistence(result.sites);
    return SitesListResult(
      sites: sites,
      total: result.total,
      page: result.page,
      limit: result.limit,
      nextCursor: result.nextCursor,
      servedFromCache: result.servedFromCache,
      isStaleFallback: result.isStaleFallback,
      cachedAt: result.cachedAt,
    );
  }

  Future<PollutionSite> _mergeUpvotesIntoSite(PollutionSite site) async {
    final List<PollutionSite> merged =
        await _applyLocalUpvotePersistence(<PollutionSite>[site]);
    return merged.first;
  }

  @override
  Future<SitesListResult> getSites({
    double? latitude,
    double? longitude,
    double radiusKm = 10,
    String? status,
    int page = 1,
    int limit = 20,
    String sort = 'hybrid',
    String mode = 'for_you',
    bool explain = false,
    String? cursor,
  }) async {
    final List<String> queryParams = <String>['page=$page', 'limit=$limit'];
    if (latitude != null) queryParams.add('lat=$latitude');
    if (longitude != null) queryParams.add('lng=$longitude');
    queryParams.add('radiusKm=$radiusKm');
    if (status != null && status.isNotEmpty) queryParams.add('status=$status');
    queryParams.add('sort=$sort');
    queryParams.add('mode=$mode');
    queryParams.add('explain=$explain');
    if (cursor != null && cursor.isNotEmpty) queryParams.add('cursor=$cursor');
    final String path = '/sites?${queryParams.join('&')}';
    final String cacheKey = _feedCacheKey(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      status: status,
      page: page,
      limit: limit,
      sort: sort,
      mode: mode,
      explain: explain,
      cursor: cursor,
    );
    final String scopeKey = _feedScopeKey(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      status: status,
      limit: limit,
      sort: sort,
      mode: mode,
      explain: explain,
    );
    final now = DateTime.now();
    final cacheHit = _memoryFeedCache[cacheKey];
    if (cacheHit != null &&
        now.difference(cacheHit.cachedAt) <= _feedCacheTtl) {
      return _mergeUpvotesIntoSitesList(
        SitesListResult(
          sites: cacheHit.result.sites,
          total: cacheHit.result.total,
          page: cacheHit.result.page,
          limit: cacheHit.result.limit,
          nextCursor: cacheHit.result.nextCursor,
          servedFromCache: true,
          isStaleFallback: false,
          cachedAt: cacheHit.cachedAt,
        ),
      );
    }

    try {
      final ApiResponse response = await _client.get(path);
      final Map<String, dynamic>? json = response.json;
      if (json == null) throw AppError.unknown();
      final SitesListResult parsed = _sitesListResultFromJson(
        json,
        page: page,
        limit: limit,
      );
      final SitesListResult result = await _mergeUpvotesIntoSitesList(parsed);
      _memoryFeedCache[cacheKey] = (result: result, cachedAt: now);
      unawaited(
        _persistFeedSnapshot(
          scopeKey: scopeKey,
          requestKey: cacheKey,
          payload: json,
          now: now,
          page: page,
          cursor: cursor,
          nextCursor: result.nextCursor,
        ),
      );
      return result;
    } on AppError {
      final fallback = await _loadPersistedFeedSnapshot(
        requestKey: cacheKey,
        scopeKey: scopeKey,
        page: page,
      );
      if (fallback != null) {
        final DateTime fallbackCachedAt = fallback.cachedAt ?? now;
        final SitesListResult merged = await _mergeUpvotesIntoSitesList(fallback);
        _memoryFeedCache[cacheKey] = (
          result: merged,
          cachedAt: fallbackCachedAt,
        );
        return SitesListResult(
          sites: merged.sites,
          total: merged.total,
          page: merged.page,
          limit: merged.limit,
          nextCursor: merged.nextCursor,
          servedFromCache: true,
          isStaleFallback: true,
          cachedAt: fallbackCachedAt,
        );
      }
      rethrow;
    }
  }

  @override
  Future<MapSitesResult> getSitesForMap({
    required double latitude,
    required double longitude,
    double radiusKm = 80,
    int limit = 200,
    double? minLatitude,
    double? maxLatitude,
    double? minLongitude,
    double? maxLongitude,
    String mapDetail = SitesRepository.mapDetailLite,
  }) async {
    final List<String> queryParams = <String>[
      'lat=$latitude',
      'lng=$longitude',
      'radiusKm=$radiusKm',
      'limit=$limit',
      'detail=$mapDetail',
      if (minLatitude != null) 'minLat=$minLatitude',
      if (maxLatitude != null) 'maxLat=$maxLatitude',
      if (minLongitude != null) 'minLng=$minLongitude',
      if (maxLongitude != null) 'maxLng=$maxLongitude',
    ];
    try {
      final ApiResponse response = await _client.get(
        '/sites/map?${queryParams.join('&')}',
      );
      final Map<String, dynamic>? json = response.json;
      if (json == null) {
        throw AppError.unknown();
      }
      unawaited(_persistMapSnapshot(json));
      final MapSitesResult parsed = _mapSitesResultFromPayload(json);
      final List<PollutionSite> merged =
          await _applyLocalUpvotePersistence(parsed.sites);
      return MapSitesResult(
        sites: merged,
        servedFromCache: parsed.servedFromCache,
        cachedAt: parsed.cachedAt,
        isStaleFallback: parsed.isStaleFallback,
        signedMediaExpiresAt: parsed.signedMediaExpiresAt,
      );
    } on AppError {
      final MapSitesResult? fallback = await _loadPersistedMapSnapshot();
      if (fallback != null) {
        final List<PollutionSite> merged =
            await _applyLocalUpvotePersistence(fallback.sites);
        return MapSitesResult(
          sites: merged,
          servedFromCache: fallback.servedFromCache,
          cachedAt: fallback.cachedAt,
          isStaleFallback: fallback.isStaleFallback,
          signedMediaExpiresAt: fallback.signedMediaExpiresAt,
        );
      }
      rethrow;
    }
  }

  SitesListResult _sitesListResultFromJson(
    Map<String, dynamic> json, {
    required int page,
    required int limit,
  }) {
    final List<dynamic> data = json['data'] as List<dynamic>? ?? <dynamic>[];
    final List<PollutionSite> sites = data
        .whereType<Map<String, dynamic>>()
        .map<PollutionSite>(_siteListItemFromJson)
        .toList();
    final Map<String, dynamic>? meta = json['meta'] as Map<String, dynamic>?;
    final int total = (meta?['total'] as num?)?.toInt() ?? sites.length;
    final int pageVal = (meta?['page'] as num?)?.toInt() ?? page;
    final int limitVal = (meta?['limit'] as num?)?.toInt() ?? limit;
    return SitesListResult(
      sites: sites,
      total: total,
      page: pageVal,
      limit: limitVal,
      nextCursor: meta?['nextCursor'] as String?,
    );
  }

  /// Feed payloads include per-user flags (`isUpvotedByMe`). Cache must vary by account.
  String _feedAuthCacheSegment() {
    final String? uid = _authState?.userId;
    if (uid != null && uid.isNotEmpty) {
      return uid;
    }
    return 'anon';
  }

  String _feedCacheKey({
    required double? latitude,
    required double? longitude,
    required double radiusKm,
    required String? status,
    required int page,
    required int limit,
    required String sort,
    required String mode,
    required bool explain,
    required String? cursor,
  }) {
    return [
      _feedAuthCacheSegment(),
      latitude?.toStringAsFixed(4) ?? '',
      longitude?.toStringAsFixed(4) ?? '',
      radiusKm.toStringAsFixed(1),
      status ?? '',
      page.toString(),
      limit.toString(),
      sort,
      mode,
      explain ? '1' : '0',
      cursor ?? '',
    ].join('|');
  }

  String _feedScopeKey({
    required double? latitude,
    required double? longitude,
    required double radiusKm,
    required String? status,
    required int limit,
    required String sort,
    required String mode,
    required bool explain,
  }) {
    return [
      _feedAuthCacheSegment(),
      latitude?.toStringAsFixed(4) ?? '',
      longitude?.toStringAsFixed(4) ?? '',
      radiusKm.toStringAsFixed(1),
      status ?? '',
      limit.toString(),
      sort,
      mode,
      explain ? '1' : '0',
    ].join('|');
  }

  Future<void> _persistFeedSnapshot({
    required String scopeKey,
    required String requestKey,
    required Map<String, dynamic> payload,
    required DateTime now,
    required int page,
    required String? cursor,
    required String? nextCursor,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final decoded = _decodePersistedFeedStore(
      prefs.getString(_feedPersistedCacheKey),
    );
    final Map<String, dynamic> feeds =
        (decoded['feeds'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> scope =
        (feeds[scopeKey] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final List<dynamic> existingPages =
        (scope['pages'] as List<dynamic>?) ?? <dynamic>[];

    final List<Map<String, dynamic>> pages = existingPages
        .whereType<Map<String, dynamic>>()
        .where((entry) {
          final int cachedAtMs = (entry['cachedAtMs'] as num?)?.toInt() ?? 0;
          if (cachedAtMs <= 0) return false;
          final DateTime cachedAt = DateTime.fromMillisecondsSinceEpoch(
            cachedAtMs,
          );
          return now.difference(cachedAt) <= _feedPersistedCacheTtl;
        })
        .toList();

    if ((cursor == null || cursor.isEmpty) && page == 1) {
      pages.clear();
    }
    pages.removeWhere(
      (entry) => (entry['requestKey'] as String?) == requestKey,
    );
    pages.add(<String, dynamic>{
      'requestKey': requestKey,
      'page': page,
      'cursor': cursor ?? '',
      'nextCursor': nextCursor ?? '',
      'cachedAtMs': now.millisecondsSinceEpoch,
      'payload': payload,
    });
    pages.sort((a, b) {
      final int pageA = (a['page'] as num?)?.toInt() ?? 1;
      final int pageB = (b['page'] as num?)?.toInt() ?? 1;
      return pageA.compareTo(pageB);
    });
    if (pages.length > _maxPersistedPagesPerFeed) {
      pages.removeRange(0, pages.length - _maxPersistedPagesPerFeed);
    }

    feeds[scopeKey] = <String, dynamic>{
      'updatedAtMs': now.millisecondsSinceEpoch,
      'pages': pages,
    };
    if (feeds.length > _maxPersistedFeeds) {
      final entries = feeds.entries.toList()
        ..sort((a, b) {
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
      final allowed = entries
          .take(_maxPersistedFeeds)
          .map((e) => e.key)
          .toSet();
      feeds.removeWhere((key, value) => !allowed.contains(key));
    }

    final wrapper = <String, dynamic>{'version': 2, 'feeds': feeds};
    await prefs.setString(_feedPersistedCacheKey, jsonEncode(wrapper));
  }

  Map<String, dynamic> _decodePersistedFeedStore(String? raw) {
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return <String, dynamic>{};
    return decoded;
  }

  Future<SitesListResult?> _loadPersistedFeedSnapshot({
    required String requestKey,
    required String scopeKey,
    required int page,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final decoded = _decodePersistedFeedStore(
      prefs.getString(_feedPersistedCacheKey),
    );
    final Map<String, dynamic> feeds =
        (decoded['feeds'] as Map<String, dynamic>?) ?? const {};
    final Map<String, dynamic>? scope =
        feeds[scopeKey] as Map<String, dynamic>?;
    if (scope == null) return null;
    final List<dynamic> pages =
        (scope['pages'] as List<dynamic>?) ?? const <dynamic>[];

    Map<String, dynamic>? selected = pages
        .whereType<Map<String, dynamic>>()
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (entry) => (entry?['requestKey'] as String?) == requestKey,
          orElse: () => null,
        );
    selected ??= pages
        .whereType<Map<String, dynamic>>()
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (entry) => ((entry?['page'] as num?)?.toInt() ?? -1) == page,
          orElse: () => null,
        );
    if (selected == null) return null;

    final int cachedAtMs = (selected['cachedAtMs'] as num?)?.toInt() ?? 0;
    if (cachedAtMs <= 0) return null;
    final DateTime cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMs);
    if (DateTime.now().difference(cachedAt) > _feedPersistedCacheTtl) {
      return null;
    }

    final dynamic payload = selected['payload'];
    if (payload is! Map<String, dynamic>) return null;
    final int limit =
        ((payload['meta'] as Map<String, dynamic>?)?['limit'] as num?)
            ?.toInt() ??
        20;
    final int resolvedPage = ((selected['page'] as num?)?.toInt() ?? page)
        .clamp(1, 999999);
    final SitesListResult parsed = _sitesListResultFromJson(
      payload,
      page: resolvedPage,
      limit: limit,
    );
    return SitesListResult(
      sites: parsed.sites,
      total: parsed.total,
      page: parsed.page,
      limit: parsed.limit,
      nextCursor: parsed.nextCursor,
      cachedAt: cachedAt,
    );
  }

  Future<void> _clearFeedCaches() async {
    _memoryFeedCache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_feedPersistedCacheKey);
    await prefs.remove(_mapPersistedCacheKey);
  }

  Future<void> _persistMapSnapshot(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final wrapper = <String, dynamic>{
      'cachedAtMs': DateTime.now().millisecondsSinceEpoch,
      'payload': payload,
    };
    await prefs.setString(_mapPersistedCacheKey, jsonEncode(wrapper));
  }

  Future<MapSitesResult?> _loadPersistedMapSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_mapPersistedCacheKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final int cachedAtMs = (decoded['cachedAtMs'] as num?)?.toInt() ?? 0;
    if (cachedAtMs <= 0) {
      return null;
    }
    final DateTime cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMs);
    if (DateTime.now().difference(cachedAt) > _mapPersistedCacheTtl) {
      return null;
    }
    final Object? payload = decoded['payload'];
    if (payload is! Map<String, dynamic>) {
      return null;
    }
    final MapSitesResult parsed = _mapSitesResultFromPayload(
      payload,
      servedFromCache: true,
      cachedAt: cachedAt,
      isStaleFallback: true,
    );
    return parsed.sites.isEmpty ? null : parsed;
  }

  @override
  Future<PollutionSite?> getSiteById(String id) async {
    try {
      final ApiResponse response = await _client.get('/sites/$id');
      final Map<String, dynamic>? json = response.json;
      if (json == null) return null;
      final PollutionSite site = _siteDetailFromJson(json);
      return _mergeUpvotesIntoSite(site);
    } on AppError catch (e) {
      if (e.code == 'NOT_FOUND' || e.code == 'SITE_NOT_FOUND') return null;
      rethrow;
    }
  }

  @override
  Future<EngagementSnapshot> upvoteSite(String id) async {
    final ApiResponse response = await _client.post('/sites/$id/upvote');
    unawaited(_clearFeedCaches());
    final EngagementSnapshot snapshot =
        _engagementSnapshotFromJson(response.json);
    if (snapshot.isUpvotedByMe) {
      await _rememberLocalUpvote(id);
    }
    return snapshot;
  }

  @override
  Future<EngagementSnapshot> removeSiteUpvote(String id) async {
    final ApiResponse response = await _client.delete('/sites/$id/upvote');
    unawaited(_clearFeedCaches());
    final EngagementSnapshot snapshot =
        _engagementSnapshotFromJson(response.json);
    if (!snapshot.isUpvotedByMe) {
      await _forgetLocalUpvote(id);
    }
    return snapshot;
  }

  @override
  Future<EngagementSnapshot> saveSite(String id) async {
    final ApiResponse response = await _client.post('/sites/$id/save');
    unawaited(_clearFeedCaches());
    return _engagementSnapshotFromJson(response.json);
  }

  @override
  Future<EngagementSnapshot> unsaveSite(String id) async {
    final ApiResponse response = await _client.delete('/sites/$id/save');
    unawaited(_clearFeedCaches());
    return _engagementSnapshotFromJson(response.json);
  }

  @override
  Future<EngagementSnapshot> shareSite(
    String id, {
    String channel = 'native',
  }) async {
    final ApiResponse response = await _client.post(
      '/sites/$id/share',
      body: <String, dynamic>{'channel': channel},
    );
    unawaited(_clearFeedCaches());
    return _engagementSnapshotFromJson(response.json);
  }

  @override
  Future<SiteCommentsResult> getSiteComments(
    String id, {
    int page = 1,
    int limit = 20,
    String sort = 'top',
    String? parentId,
  }) async {
    final query = <String>[
      'page=$page',
      'limit=$limit',
      'sort=$sort',
      if (parentId != null && parentId.isNotEmpty) 'parentId=$parentId',
    ].join('&');
    final ApiResponse response = await _client.get(
      '/sites/$id/comments?$query',
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    final List<dynamic> data = json['data'] as List<dynamic>? ?? <dynamic>[];
    final List<SiteCommentItem> items = data
        .whereType<Map<String, dynamic>>()
        .map<SiteCommentItem>(_siteCommentFromJson)
        .toList();
    final Map<String, dynamic>? meta = json['meta'] as Map<String, dynamic>?;
    return SiteCommentsResult(
      items: items,
      page: (meta?['page'] as num?)?.toInt() ?? page,
      limit: (meta?['limit'] as num?)?.toInt() ?? limit,
      total: (meta?['total'] as num?)?.toInt() ?? items.length,
    );
  }

  SiteUpvoterItem _siteUpvoterFromJson(Map<String, dynamic> json) {
    final String userId =
        '${json['userId'] ?? json['user_id'] ?? ''}'.trim();
    final String displayName =
        '${json['displayName'] ?? json['display_name'] ?? ''}'.trim();
    final Object? av = json['avatarUrl'] ?? json['avatar_url'];
    final String? avatarUrl =
        av is String && av.trim().isNotEmpty ? av.trim() : null;
    final Object? rawAt = json['upvotedAt'] ?? json['upvoted_at'];
    final DateTime upvotedAt = rawAt is String && rawAt.isNotEmpty
        ? (DateTime.tryParse(rawAt) ?? DateTime.fromMillisecondsSinceEpoch(0))
        : DateTime.fromMillisecondsSinceEpoch(0);
    return SiteUpvoterItem(
      userId: userId.isEmpty ? 'user-${displayName.hashCode}' : userId,
      displayName: displayName.isEmpty ? 'Anonymous' : displayName,
      avatarUrl: avatarUrl,
      upvotedAt: upvotedAt,
    );
  }

  @override
  Future<SiteUpvotesResult> getSiteUpvotes(
    String id, {
    int page = 1,
    int limit = 20,
  }) async {
    final String query = 'page=$page&limit=$limit';
    final ApiResponse response = await _client.get('/sites/$id/upvotes?$query');
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    final List<dynamic> data = json['data'] as List<dynamic>? ?? <dynamic>[];
    final List<SiteUpvoterItem> items = data
        .whereType<Map<String, dynamic>>()
        .map<SiteUpvoterItem>(_siteUpvoterFromJson)
        .toList();
    final Map<String, dynamic>? meta = json['meta'] as Map<String, dynamic>?;
    return SiteUpvotesResult(
      items: items,
      page: (meta?['page'] as num?)?.toInt() ?? page,
      limit: (meta?['limit'] as num?)?.toInt() ?? limit,
      total: (meta?['total'] as num?)?.toInt() ?? items.length,
      hasMore: meta?['hasMore'] as bool? ?? false,
    );
  }

  @override
  Future<SiteCommentItem> createSiteComment(
    String id,
    String body, {
    String? parentId,
  }) async {
    final ApiResponse response = await _client.post(
      '/sites/$id/comments',
      body: <String, dynamic>{
        'body': body,
        if (parentId != null && parentId.isNotEmpty) 'parentId': parentId,
      },
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    return _siteCommentFromJson(json);
  }

  @override
  Future<void> updateSiteComment(
    String siteId,
    String commentId,
    String body,
  ) async {
    await _client.patch(
      '/sites/$siteId/comments/$commentId',
      body: <String, dynamic>{'body': body},
    );
  }

  @override
  Future<void> deleteSiteComment(String siteId, String commentId) async {
    await _client.delete('/sites/$siteId/comments/$commentId');
  }

  @override
  Future<SiteCommentLikeSnapshot> likeSiteComment(
    String siteId,
    String commentId,
  ) async {
    final response = await _client.post(
      '/sites/$siteId/comments/$commentId/like',
    );
    return _siteCommentLikeSnapshotFromJson(response.json);
  }

  @override
  Future<SiteCommentLikeSnapshot> unlikeSiteComment(
    String siteId,
    String commentId,
  ) async {
    final response = await _client.delete(
      '/sites/$siteId/comments/$commentId/like',
    );
    return _siteCommentLikeSnapshotFromJson(response.json);
  }

  @override
  Future<SiteMediaResult> getSiteMedia(
    String id, {
    int page = 1,
    int limit = 24,
  }) async {
    final ApiResponse response = await _client.get(
      '/sites/$id/media?page=$page&limit=$limit',
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    final List<dynamic> data = json['data'] as List<dynamic>? ?? <dynamic>[];
    final List<SiteMediaItem> items = data
        .whereType<Map<String, dynamic>>()
        .map<SiteMediaItem>(
          (Map<String, dynamic> item) => SiteMediaItem(
            id: item['id'] as String? ?? '',
            reportId: item['reportId'] as String? ?? '',
            url: item['url'] as String? ?? '',
            createdAt:
                DateTime.tryParse(item['createdAt'] as String? ?? '') ??
                DateTime.now(),
          ),
        )
        .toList();
    final Map<String, dynamic>? meta = json['meta'] as Map<String, dynamic>?;
    return SiteMediaResult(
      items: items,
      page: (meta?['page'] as num?)?.toInt() ?? page,
      limit: (meta?['limit'] as num?)?.toInt() ?? limit,
      total: (meta?['total'] as num?)?.toInt() ?? items.length,
    );
  }

  @override
  Future<void> trackFeedEvent(
    String siteId, {
    required String eventType,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _client.post(
        '/sites/feed/events',
        body: <String, dynamic>{
          'siteId': siteId,
          'eventType': eventType,
          if (sessionId != null && sessionId.isNotEmpty) 'sessionId': sessionId,
          ...?metadata?.letMap('metadata'),
        },
      );
    } on AppError {
      // Fire-and-forget feed analytics; callers use unawaited. Ignore failures
      // (logged out, expired token, offline, throttled) so they never surface
      // as unhandled async exceptions.
    }
  }

  @override
  Future<void> submitFeedFeedback(
    String siteId, {
    required String feedbackType,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) async {
    await _client.post(
      '/sites/$siteId/feed-feedback',
      body: <String, dynamic>{
        'feedbackType': feedbackType,
        if (sessionId != null && sessionId.isNotEmpty) 'sessionId': sessionId,
        ...?metadata?.letMap('metadata'),
      },
    );
    unawaited(_clearFeedCaches());
  }

  PollutionSite _siteListItemFromJson(Map<String, dynamic> json) {
    final String desc = json['description'] as String? ?? '';
    final String latestTitle = json['latestReportTitle'] as String? ?? '';
    final String latest = json['latestReportDescription'] as String? ?? '';
    final String? addr = json['address'] as String?;
    final String trimmedAddr = addr?.trim() ?? '';
    final String title = desc.isNotEmpty
        ? desc
        : (_normalizeFeedTitle(latestTitle).isNotEmpty
              ? _normalizeFeedTitle(latestTitle)
              : (latest.isNotEmpty
                    ? latest
                    : (trimmedAddr.isNotEmpty ? trimmedAddr : 'Pollution site')));
    final double distanceKm = json.containsKey('distanceKm')
        ? ((json['distanceKm'] as num?)?.toDouble() ?? -1)
        : -1;
    final int reportCount = (json['reportCount'] as num?)?.toInt() ?? 0;
    final String statusStr = json['status'] as String? ?? 'REPORTED';
    final (String statusLabel, Color statusColor) = _siteStatusToLabelAndColor(
      statusStr,
    );
    final int score =
        (json['upvotesCount'] as num?)?.toInt() ?? reportCount * 5;
    final int commentsCount = (json['commentsCount'] as num?)?.toInt() ?? 0;
    final int sharesCount = (json['sharesCount'] as num?)?.toInt() ?? 0;
    final bool isUpvotedByMe =
        _jsonBoolField(json, 'isUpvotedByMe', 'is_upvoted_by_me');
    final bool isSavedByMe = _jsonBoolField(json, 'isSavedByMe', 'is_saved_by_me');
    final double? lat = (json['latitude'] as num?)?.toDouble();
    final double? lng = (json['longitude'] as num?)?.toDouble();
    final List<dynamic> mediaUrlsJson =
        json['latestReportMediaUrls'] as List<dynamic>? ?? <dynamic>[];
    final List<String> imageUrls = mediaUrlsJson
        .whereType<String>()
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toSet()
        .toList();
    final String? firstImageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;
    final ImageProvider imageProvider = firstImageUrl != null
        ? imageProviderForSiteMedia(firstImageUrl)
        : _placeholderImage;
    return PollutionSite(
      id: json['id'] as String? ?? '',
      title: title,
      description: desc.isNotEmpty
          ? desc
          : (latestTitle.isNotEmpty && latest.isNotEmpty
                ? latest
                : (latestTitle.isNotEmpty ? latestTitle : latest)),
      statusLabel: statusLabel,
      statusColor: statusColor,
      distanceKm: distanceKm,
      score: score,
      shareCount: sharesCount,
      isUpvotedByMe: isUpvotedByMe,
      isSavedByMe: isSavedByMe,
      participantCount: 0,
      imageProvider: imageProvider,
      primaryImageUrl: firstImageUrl,
      images: imageUrls.isNotEmpty
          ? imageUrls.map<ImageProvider>(imageProviderForSiteMedia).toList()
          : null,
      commentsCount: commentsCount,
      firstReport: null,
      coReporterNames: <String>[],
      latitude: lat,
      longitude: lng,
      feedReasons:
          (json['rankingReasons'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<String>()
              .toList(),
      rankingScore: (json['rankingScore'] as num?)?.toDouble(),
      rankingComponents: _rankingComponentsFromJson(json['rankingComponents']),
      latestReporterName: json['latestReportReporterName'] as String?,
      latestReporterAvatarUrl: json['latestReportReporterAvatarUrl'] as String?,
      latestReporterUserId: json['latestReportReporterId'] as String?,
      latestReportAt: () {
        final String? s = json['latestReportCreatedAt'] as String?;
        if (s == null || s.isEmpty) return null;
        return DateTime.tryParse(s);
      }(),
    );
  }

  MapSitesResult _mapSitesResultFromPayload(
    Map<String, dynamic> json, {
    bool servedFromCache = false,
    DateTime? cachedAt,
    bool isStaleFallback = false,
  }) {
    final List<dynamic> data = json['data'] as List<dynamic>? ?? <dynamic>[];
    final List<PollutionSite> sites = data
        .whereType<Map<String, dynamic>>()
        .map<PollutionSite>(_siteListItemFromJson)
        .toList();
    DateTime? signedMediaExpiresAt;
    final Object? metaRaw = json['meta'];
    if (metaRaw is Map<String, dynamic>) {
      final String? s = metaRaw['signedMediaExpiresAt'] as String?;
      if (s != null && s.isNotEmpty) {
        signedMediaExpiresAt = DateTime.tryParse(s);
      }
    }
    return MapSitesResult(
      sites: sites,
      servedFromCache: servedFromCache,
      cachedAt: cachedAt,
      isStaleFallback: isStaleFallback,
      signedMediaExpiresAt: signedMediaExpiresAt,
    );
  }

  PollutionSite _siteDetailFromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> root = _siteEntityJsonRoot(json);
    final String desc = root['description'] as String? ?? '';
    final List<dynamic> reportsJson =
        root['reports'] as List<dynamic>? ?? <dynamic>[];
    final List<Map<String, dynamic>> reports = _mapListOfObjects(reportsJson);
    final List<dynamic> eventsJson =
        root['events'] as List<dynamic>? ?? <dynamic>[];
    final List<Map<String, dynamic>> events = _mapListOfObjects(eventsJson);

    SiteReport? firstReport;
    String? latestReporterUserId;
    final List<String> orderedUniqueImageUrls = <String>[];
    final Set<String> seenImageUrls = <String>{};
    List<String> aggregatedCoReporterNames = <String>[];
    List<CoReporterProfile> aggregatedCoReporterProfiles = <CoReporterProfile>[];

    if (reports.isNotEmpty) {
      final Map<String, dynamic> first = reports.first;
      latestReporterUserId =
          first['reporterId'] as String? ?? first['reporter_id'] as String?;
      for (final Map<String, dynamic> r in reports) {
        final List<dynamic> mediaList = _reportMediaUrlsList(r);
        for (final dynamic m in mediaList) {
          if (m is String && m.isNotEmpty && seenImageUrls.add(m)) {
            orderedUniqueImageUrls.add(m);
          }
        }
      }
      final List<dynamic> firstMediaList = _reportMediaUrlsList(first);
      final List<ImageProvider> firstReportImages = firstMediaList
          .whereType<String>()
          .map<ImageProvider>((String u) => imageProviderForSiteMedia(u))
          .toList();
      final Map<String, dynamic>? reporterJson =
          _jsonObjectToStringKeyedMap(first['reporter']);
      final String reporterFirstName =
          '${reporterJson?['firstName'] ?? reporterJson?['first_name'] ?? ''}'
              .trim();
      final String reporterLastName =
          '${reporterJson?['lastName'] ?? reporterJson?['last_name'] ?? ''}'
              .trim();
      final String? reporterAvatarUrl =
          reporterJson?['avatarUrl'] as String? ??
          reporterJson?['avatar_url'] as String?;
      final String reporterName = '$reporterFirstName $reporterLastName'.trim();
      final String reportTitle = (first['title'] as String?)?.trim() ?? '';
      final String bodyTrim = (first['description'] as String?)?.trim() ?? '';
      final String resolvedTitle = reportTitle.isNotEmpty
          ? reportTitle
          : (bodyTrim.isNotEmpty ? bodyTrim : 'Report');
      final String? resolvedBody =
          bodyTrim.isNotEmpty && bodyTrim != resolvedTitle ? bodyTrim : null;
      firstReport = SiteReport(
        id: first['id'] as String? ?? '',
        reporterName: reporterName.isEmpty ? 'Anonymous' : reporterName,
        reportedAt: DateTime.tryParse(
              first['createdAt'] as String? ??
                  first['created_at'] as String? ??
                  '',
            ) ??
            DateTime.now(),
        title: resolvedTitle,
        description: resolvedBody,
        images: firstReportImages,
        reporterAvatarUrl: reporterAvatarUrl,
      );
      final Map<String, ({String name, DateTime? reportedAt, String? avatarUrl})>
          coByUserId =
          <String, ({String name, DateTime? reportedAt, String? avatarUrl})>{};
      for (final Map<String, dynamic> r in reports) {
        final List<dynamic> coList = _reportCoReportersList(r);
        for (final dynamic rawCo in coList) {
          final Map<String, dynamic>? co = _jsonObjectToStringKeyedMap(rawCo);
          if (co == null) continue;
          final String? userId = _coReporterRowUserId(co);
          if (userId == null) continue;
          final Map<String, dynamic>? user = _coReporterRowUser(co);
          final String name = _coReporterDisplayName(user);
          final DateTime? reportedAt = _coReporterRowReportedAt(co);
          final Object? avRaw = user?['avatarUrl'] ?? user?['avatar_url'];
          final String? avatarUrl =
              avRaw is String && avRaw.trim().isNotEmpty ? avRaw.trim() : null;
          final ({String name, DateTime? reportedAt, String? avatarUrl})?
              existing = coByUserId[userId];
          if (existing == null) {
            coByUserId[userId] =
                (name: name, reportedAt: reportedAt, avatarUrl: avatarUrl);
          } else {
            final DateTime? p = existing.reportedAt;
            final bool useIncomingTime = reportedAt != null &&
                (p == null || reportedAt.isBefore(p));
            final String mergedName = useIncomingTime
                ? _preferRicherCoReporterName(name, existing.name)
                : _preferRicherCoReporterName(existing.name, name);
            final DateTime? mergedAt =
                useIncomingTime ? reportedAt : existing.reportedAt;
            final String? mergedAvatar = useIncomingTime
                ? _preferNonEmptyString(avatarUrl, existing.avatarUrl)
                : _preferNonEmptyString(existing.avatarUrl, avatarUrl);
            coByUserId[userId] = (
              name: mergedName,
              reportedAt: mergedAt,
              avatarUrl: mergedAvatar,
            );
          }
        }
      }
      final List<MapEntry<String, ({String name, DateTime? reportedAt, String? avatarUrl})>>
          sortedCo = coByUserId.entries.toList()
            ..sort((
              MapEntry<String, ({String name, DateTime? reportedAt, String? avatarUrl})>
                  a,
              MapEntry<String, ({String name, DateTime? reportedAt, String? avatarUrl})>
                  b,
            ) {
              final DateTime? ta = a.value.reportedAt;
              final DateTime? tb = b.value.reportedAt;
              if (ta != null && tb != null) return ta.compareTo(tb);
              if (ta != null) return -1;
              if (tb != null) return 1;
              return a.value.name.compareTo(b.value.name);
            });
      aggregatedCoReporterNames = sortedCo
          .map(
            (MapEntry<String, ({String name, DateTime? reportedAt, String? avatarUrl})> e) =>
                e.value.name,
          )
          .toList();
      aggregatedCoReporterProfiles = sortedCo
          .map(
            (MapEntry<String, ({String name, DateTime? reportedAt, String? avatarUrl})> e) =>
                CoReporterProfile(
              displayName: e.value.name,
              avatarUrl: e.value.avatarUrl,
              userId: e.key,
            ),
          )
          .toList();
    }

    final List<String> fromApiCoReporterNames =
        _siteDetailCoReporterNamesFromApiField(
      root['coReporterNames'] ?? root['co_reporter_names'],
    );
    final List<CoReporterProfile> fromApiCoReporterProfiles =
        _coReporterSummariesFromApiField(
      root['coReporterSummaries'] ?? root['co_reporter_summaries'],
    );
    final List<CoReporterProfile> coReporterProfiles;
    final List<String> coReporterNames;
    if (fromApiCoReporterProfiles.isNotEmpty) {
      coReporterProfiles = fromApiCoReporterProfiles;
      coReporterNames = fromApiCoReporterNames.isNotEmpty
          ? fromApiCoReporterNames
          : fromApiCoReporterProfiles.map((CoReporterProfile p) => p.displayName).toList();
    } else if (aggregatedCoReporterProfiles.isNotEmpty) {
      coReporterProfiles = aggregatedCoReporterProfiles;
      coReporterNames = fromApiCoReporterNames.isNotEmpty
          ? fromApiCoReporterNames
          : aggregatedCoReporterNames;
    } else if (fromApiCoReporterNames.isNotEmpty) {
      coReporterProfiles = fromApiCoReporterNames
          .map((String n) => CoReporterProfile(displayName: n))
          .toList();
      coReporterNames = fromApiCoReporterNames;
    } else {
      coReporterProfiles = <CoReporterProfile>[];
      coReporterNames = <String>[];
    }

    final Map<String, dynamic>? firstReportJson = reports.isNotEmpty
        ? reports.first
        : null;
    final String latestTitle = _normalizeFeedTitle(
      firstReportJson?['title'] as String? ?? '',
    );
    final String latestDesc = firstReportJson?['description'] as String? ?? '';
    final String title = desc.isNotEmpty
        ? desc
        : (latestTitle.trim().isNotEmpty
              ? latestTitle.trim()
              : (latestDesc.isNotEmpty ? latestDesc : 'Pollution site'));
    final String statusStr = root['status'] as String? ?? 'REPORTED';
    final (String statusLabel, Color statusColor) = _siteStatusToLabelAndColor(
      statusStr,
    );
    final int reportCount = reports.length;
    final int score =
        (root['upvotesCount'] as num?)?.toInt() ?? reportCount * 5;
    final int commentsCount = (root['commentsCount'] as num?)?.toInt() ?? 0;
    final int sharesCount = (root['sharesCount'] as num?)?.toInt() ?? 0;
    final bool isUpvotedByMe =
        _jsonBoolField(root, 'isUpvotedByMe', 'is_upvoted_by_me');
    final bool isSavedByMe = _jsonBoolField(root, 'isSavedByMe', 'is_saved_by_me');

    int totalParticipants = 0;
    final List<CleaningEvent> cleaningEvents = <CleaningEvent>[];
    for (final Map<String, dynamic> ev in events) {
      final int pc =
          ((ev['participantCount'] ?? ev['participant_count']) as num?)
              ?.toInt() ??
          0;
      totalParticipants += pc;
      final String scheduledStr =
          ev['scheduledAt'] as String? ?? ev['scheduled_at'] as String? ?? '';
      final DateTime dateTime =
          DateTime.tryParse(scheduledStr) ?? DateTime.now();
      cleaningEvents.add(
        CleaningEvent(
          id: ev['id'] as String? ?? '',
          title: 'Cleanup event',
          dateTime: dateTime,
          participantCount: pc,
          statusLabel: 'Upcoming',
          statusColor: AppColors.primaryDark,
        ),
      );
    }

    final List<ImageProvider> imageProviders = orderedUniqueImageUrls
        .map<ImageProvider>(imageProviderForSiteMedia)
        .toList();
    final ImageProvider imageProvider = imageProviders.isNotEmpty
        ? imageProviders.first
        : _placeholderImage;
    final String? primaryImageUrl = orderedUniqueImageUrls.isNotEmpty
        ? orderedUniqueImageUrls.first
        : null;

    final double? lat = (root['latitude'] as num?)?.toDouble();
    final double? lng = (root['longitude'] as num?)?.toDouble();
    int mergedDuplicateChildCountTotal =
        (root['mergedDuplicateChildCountTotal'] as num?)?.toInt() ??
            (root['merged_duplicate_child_count_total'] as num?)?.toInt() ??
            0;
    if (mergedDuplicateChildCountTotal <= 0) {
      for (final Map<String, dynamic> r in reports) {
        mergedDuplicateChildCountTotal +=
            (r['mergedDuplicateChildCount'] as num?)?.toInt() ??
                (r['merged_duplicate_child_count'] as num?)?.toInt() ??
                0;
      }
    }
    return PollutionSite(
      id: root['id'] as String? ?? '',
      title: title,
      description: desc.isNotEmpty
          ? desc
          : (latestTitle.trim().isNotEmpty && latestDesc.isNotEmpty
                ? latestDesc
                : (latestTitle.trim().isNotEmpty ? latestTitle : latestDesc)),
      statusLabel: statusLabel,
      statusColor: statusColor,
      distanceKm: root.containsKey('distanceKm')
          ? ((root['distanceKm'] as num?)?.toDouble() ?? -1)
          : -1,
      score: score,
      shareCount: sharesCount,
      isUpvotedByMe: isUpvotedByMe,
      isSavedByMe: isSavedByMe,
      participantCount: totalParticipants,
      imageProvider: imageProvider,
      primaryImageUrl: primaryImageUrl,
      images: imageProviders.isNotEmpty ? imageProviders : null,
      commentsCount: commentsCount,
      firstReport: firstReport,
      coReporterNames: coReporterNames,
      coReporterProfiles: coReporterProfiles,
      mergedDuplicateChildCountTotal: mergedDuplicateChildCountTotal,
      cleaningEvents: cleaningEvents,
      latitude: lat,
      longitude: lng,
      feedReasons: const <String>[],
      rankingScore: null,
      rankingComponents: null,
      latestReporterName:
          firstReport != null && firstReport.reporterName != 'Anonymous'
          ? firstReport.reporterName
          : null,
      latestReporterAvatarUrl: firstReport?.reporterAvatarUrl,
      latestReportAt: firstReport?.reportedAt,
      latestReporterUserId: latestReporterUserId,
    );
  }

  Map<String, double>? _rankingComponentsFromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    final map = <String, double>{};
    for (final entry in raw.entries) {
      final val = entry.value;
      if (val is num) {
        map[entry.key] = val.toDouble();
      }
    }
    return map.isEmpty ? null : map;
  }

  EngagementSnapshot _engagementSnapshotFromJson(Map<String, dynamic>? json) {
    final Map<String, dynamic>? root = _engagementSnapshotJsonRoot(json);
    if (root == null) throw AppError.unknown();
    return EngagementSnapshot(
      siteId: root['siteId'] as String? ?? root['site_id'] as String? ?? '',
      upvotesCount: (root['upvotesCount'] as num?)?.toInt() ??
          (root['upvotes_count'] as num?)?.toInt() ??
          0,
      commentsCount: (root['commentsCount'] as num?)?.toInt() ??
          (root['comments_count'] as num?)?.toInt() ??
          0,
      savesCount: (root['savesCount'] as num?)?.toInt() ??
          (root['saves_count'] as num?)?.toInt() ??
          0,
      sharesCount: (root['sharesCount'] as num?)?.toInt() ??
          (root['shares_count'] as num?)?.toInt() ??
          0,
      isUpvotedByMe: _jsonBoolField(root, 'isUpvotedByMe', 'is_upvoted_by_me'),
      isSavedByMe: _jsonBoolField(root, 'isSavedByMe', 'is_saved_by_me'),
    );
  }

  String _normalizeFeedTitle(String input) {
    final String trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.replaceFirst(RegExp(r'^[A-Za-z ]{2,24}\s*:\s*'), '');
  }

  (String, Color) _siteStatusToLabelAndColor(String status) {
    switch (status.toUpperCase()) {
      case 'REPORTED':
        return ('Reported', AppColors.accentWarning);
      case 'VERIFIED':
        return ('Verified', AppColors.primary);
      case 'CLEANUP_SCHEDULED':
        return ('Cleanup scheduled', AppColors.accentInfo);
      case 'IN_PROGRESS':
        return ('In progress', AppColors.accentInfo);
      case 'CLEANED':
        return ('Cleaned', AppColors.primary);
      case 'DISPUTED':
        return ('Disputed', AppColors.accentDanger);
      default:
        return ('Reported', AppColors.accentWarning);
    }
  }

  SiteCommentItem _siteCommentFromJson(Map<String, dynamic> item) {
    final List<dynamic> repliesJson =
        item['replies'] as List<dynamic>? ?? <dynamic>[];
    return SiteCommentItem(
      id: item['id'] as String? ?? '',
      parentId: item['parentId'] as String?,
      authorId: item['authorId'] as String? ?? '',
      authorName: item['authorName'] as String? ?? 'Anonymous',
      body: item['body'] as String? ?? '',
      createdAt:
          DateTime.tryParse(item['createdAt'] as String? ?? '') ??
          DateTime.now(),
      likeCount: (item['likesCount'] as num?)?.toInt() ?? 0,
      isLikedByMe: item['isLikedByMe'] == true,
      replies: repliesJson
          .whereType<Map<String, dynamic>>()
          .map<SiteCommentItem>(_siteCommentFromJson)
          .toList(),
      repliesCount: (item['repliesCount'] as num?)?.toInt() ?? 0,
    );
  }

  SiteCommentLikeSnapshot _siteCommentLikeSnapshotFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) throw AppError.unknown();
    return SiteCommentLikeSnapshot(
      commentId: json['commentId'] as String? ?? '',
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      isLikedByMe: json['isLikedByMe'] == true,
    );
  }
}

extension on Map<String, dynamic> {
  Map<String, dynamic> letMap(String key) => <String, dynamic>{key: this};
}
