import 'dart:async';
import 'dart:convert';

import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/home/data/sites_json_mapper.dart';
import 'package:chisto_mobile/features/home/data/sites_local_cache.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/repositories/feed_sites_repository.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// HTTP + in-memory + disk cache for feed list, map, and site detail reads.
class ApiFeedSitesRepository implements FeedSitesRepository {
  ApiFeedSitesRepository({
    required ApiClient client,
    AuthState? authState,
    SitesLocalCache? localCache,
    SitesJsonMapper? jsonMapper,
  })  : _client = client,
        _authState = authState,
        _localCache = localCache ?? SitesLocalCache(),
        _mapper = jsonMapper ?? const SitesJsonMapper();

  final ApiClient _client;
  final AuthState? _authState;
  final SitesLocalCache _localCache;
  final SitesJsonMapper _mapper;

  static const Duration _feedCacheTtl = Duration(seconds: 20);
  static const String _localUpvoteIdsPrefix = 'site_upvote_ids_';
  static const int _localUpvoteIdsMax = 400;
  static const int _memoryFeedCacheMaxEntries = 24;

  final Map<String, ({SitesListResult result, DateTime cachedAt})>
      _memoryFeedCache = <String, ({SitesListResult result, DateTime cachedAt})>{};

  void _rememberFeedCacheEntry(
    String cacheKey, {
    required SitesListResult result,
    required DateTime cachedAt,
  }) {
    _memoryFeedCache[cacheKey] = (result: result, cachedAt: cachedAt);
    if (_memoryFeedCache.length <= _memoryFeedCacheMaxEntries) {
      return;
    }
    final List<MapEntry<String, ({SitesListResult result, DateTime cachedAt})>>
        entries = _memoryFeedCache.entries.toList()
          ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    for (final entry
        in entries.take(_memoryFeedCache.length - _memoryFeedCacheMaxEntries)) {
      _memoryFeedCache.remove(entry.key);
    }
  }

  Future<void> clearAllCaches() async {
    _memoryFeedCache.clear();
    await _localCache.clearFeedAndMapSnapshots();
  }

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

  Future<void> rememberLocalUpvote(String siteId) async {
    if (siteId.isEmpty) {
      return;
    }
    final Set<String> ids = Set<String>.from(await _readLocalUpvoteIds());
    if (ids.add(siteId)) {
      await _writeLocalUpvoteIds(ids);
    }
  }

  Future<void> forgetLocalUpvote(String siteId) async {
    if (siteId.isEmpty) {
      return;
    }
    final Set<String> ids = Set<String>.from(await _readLocalUpvoteIds());
    if (ids.remove(siteId)) {
      await _writeLocalUpvoteIds(ids);
    }
  }

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
      lastSuccessfulRefreshAt: result.lastSuccessfulRefreshAt,
      feedVariant: result.feedVariant,
    );
  }

  Future<PollutionSite> _mergeUpvotesIntoSite(PollutionSite site) async {
    final List<PollutionSite> merged =
        await _applyLocalUpvotePersistence(<PollutionSite>[site]);
    return merged.first;
  }

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

  Future<SitesListResult?> _loadPersistedFeedSnapshot({
    required String requestKey,
    required String scopeKey,
    required int page,
  }) async {
    final record = await _localCache.loadFeedPage(
      requestKey: requestKey,
      scopeKey: scopeKey,
      page: page,
    );
    if (record == null) return null;

    final int limit =
        ((record.payload['meta'] as Map<String, dynamic>?)?['limit'] as num?)
            ?.toInt() ??
        20;
    final SitesListResult parsed = _mapper.sitesListResultFromJson(
      record.payload,
      page: record.storedPage,
      limit: limit,
    );
    return SitesListResult(
      sites: parsed.sites,
      total: parsed.total,
      page: parsed.page,
      limit: parsed.limit,
      nextCursor: parsed.nextCursor,
      cachedAt: record.cachedAt,
      lastSuccessfulRefreshAt: record.cachedAt,
      feedVariant: parsed.feedVariant,
    );
  }

  Future<MapSitesResult?> _loadPersistedMapSnapshot() async {
    final record = await _localCache.loadMapSnapshot();
    if (record == null) return null;
    final MapSitesResult parsed = _mapper.mapSitesResultFromPayload(
      record.payload,
      servedFromCache: true,
      cachedAt: record.cachedAt,
      isStaleFallback: true,
    );
    return parsed.sites.isEmpty ? null : parsed;
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
    final DateTime now = DateTime.now();
    final ({SitesListResult result, DateTime cachedAt})? cacheHit =
        _memoryFeedCache[cacheKey];
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
          lastSuccessfulRefreshAt: cacheHit.result.lastSuccessfulRefreshAt,
          feedVariant: cacheHit.result.feedVariant,
        ),
      );
    }

    try {
      final ApiResponse response = await _client.get(path);
      final Map<String, dynamic>? json = response.json;
      if (json == null) throw AppError.unknown();
      final SitesListResult parsed = _mapper.sitesListResultFromJson(
        json,
        page: page,
        limit: limit,
      );
      final String feedVariant =
          response.headers['x-feed-variant']?.trim().isNotEmpty == true
              ? response.headers['x-feed-variant']!.trim()
              : (json['feedVariant'] as String? ?? 'v1');
      final SitesListResult result = await _mergeUpvotesIntoSitesList(
        SitesListResult(
          sites: parsed.sites,
          total: parsed.total,
          page: parsed.page,
          limit: parsed.limit,
          nextCursor: parsed.nextCursor,
          servedFromCache: parsed.servedFromCache,
          isStaleFallback: parsed.isStaleFallback,
          cachedAt: parsed.cachedAt,
          lastSuccessfulRefreshAt: now,
          feedVariant: feedVariant,
        ),
      );
      _rememberFeedCacheEntry(cacheKey, result: result, cachedAt: now);
      unawaited(
        _localCache.persistFeedSnapshot(
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
      final SitesListResult? fallback = await _loadPersistedFeedSnapshot(
        requestKey: cacheKey,
        scopeKey: scopeKey,
        page: page,
      );
      if (fallback != null) {
        final DateTime fallbackCachedAt = fallback.cachedAt ?? now;
        final SitesListResult merged =
            await _mergeUpvotesIntoSitesList(fallback);
        _rememberFeedCacheEntry(
          cacheKey,
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
          lastSuccessfulRefreshAt: fallback.lastSuccessfulRefreshAt,
          feedVariant: merged.feedVariant,
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
    String mapDetail = FeedSitesRepository.mapDetailLite,
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
      unawaited(_localCache.persistMapSnapshot(json));
      final MapSitesResult parsed = _mapper.mapSitesResultFromPayload(json);
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

  @override
  Future<PollutionSite?> getSiteById(String id) async {
    try {
      final ApiResponse response = await _client.get('/sites/$id');
      final Map<String, dynamic>? json = response.json;
      if (json == null) return null;
      final PollutionSite site = _mapper.siteDetailFromJson(json);
      return _mergeUpvotesIntoSite(site);
    } on AppError catch (e) {
      if (e.code == 'NOT_FOUND' || e.code == 'SITE_NOT_FOUND') return null;
      rethrow;
    }
  }
}
