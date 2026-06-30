import 'dart:async';
import 'dart:convert';

import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:chisto_infrastructure/core/serialization/safe_json.dart';
import 'package:feature_home/src/data/sites_json_mapper.dart';
import 'package:feature_home/src/data/sites_local_cache.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/domain/repositories/feed_sites_repository.dart';
import 'package:feature_home/src/domain/repositories/sites_repository_types.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// HTTP + in-memory + disk cache for feed list, map, and site detail reads.
class ApiFeedSitesRepository implements FeedSitesRepository {
  ApiFeedSitesRepository({
    required ApiClient client,
    AuthState? authState,
    SitesLocalCache? localCache,
    SitesJsonMapper? jsonMapper,
  }) : _client = client,
       _authState = authState,
       _localCache = localCache ?? SitesLocalCache(),
       _mapper = jsonMapper ?? const SitesJsonMapper();

  final ApiClient _client;
  final AuthState? _authState;
  final SitesLocalCache _localCache;
  final SitesJsonMapper _mapper;
  final Map<String, ({String etag, Map<String, dynamic> payload})>
  _mapEtagCache = <String, ({String etag, Map<String, dynamic> payload})>{};

  static const Duration _feedCacheTtl = Duration(seconds: 20);
  static const Duration _mapMemoryCacheTtl = Duration(seconds: 15);
  static const double _mapGeoSnapStepDegrees = 0.01;
  static const String _localUpvoteIdsPrefix = 'site_upvote_ids_';
  static const int _localUpvoteIdsMax = 400;
  static const int _memoryFeedCacheMaxEntries = 24;
  static const int _memoryMapCacheMaxEntries = 24;

  final Map<String, ({SitesListResult result, DateTime cachedAt})>
  _memoryFeedCache = <String, ({SitesListResult result, DateTime cachedAt})>{};

  final Map<String, ({MapSitesResult result, DateTime cachedAt})>
  _memoryMapCache = <String, ({MapSitesResult result, DateTime cachedAt})>{};

  final Map<String, Future<PollutionSite?>> _inFlightSiteById =
      <String, Future<PollutionSite?>>{};

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
    for (final entry in entries.take(
      _memoryFeedCache.length - _memoryFeedCacheMaxEntries,
    )) {
      _memoryFeedCache.remove(entry.key);
    }
  }

  Future<void> clearAllCaches() async {
    _memoryFeedCache.clear();
    _memoryMapCache.clear();
    _mapEtagCache.clear();
    await _localCache.clearFeedAndMapSnapshots();
  }

  static double _snapMapGeoCenter(double v) =>
      (v / _mapGeoSnapStepDegrees).round() * _mapGeoSnapStepDegrees;

  static double? _snapMapGeoMinEdge(double? v) {
    if (v == null) {
      return null;
    }
    return (v / _mapGeoSnapStepDegrees).floor() * _mapGeoSnapStepDegrees;
  }

  static double? _snapMapGeoMaxEdge(double? v) {
    if (v == null) {
      return null;
    }
    return (v / _mapGeoSnapStepDegrees).ceil() * _mapGeoSnapStepDegrees;
  }

  void _rememberMapMemoryEntry(
    String cacheKey, {
    required MapSitesResult result,
    required DateTime cachedAt,
  }) {
    _memoryMapCache[cacheKey] = (result: result, cachedAt: cachedAt);
    if (_memoryMapCache.length <= _memoryMapCacheMaxEntries) {
      return;
    }
    final List<MapEntry<String, ({MapSitesResult result, DateTime cachedAt})>>
    entries = _memoryMapCache.entries.toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    for (final MapEntry<String, ({MapSitesResult result, DateTime cachedAt})>
        entry
        in entries.take(_memoryMapCache.length - _memoryMapCacheMaxEntries)) {
      _memoryMapCache.remove(entry.key);
    }
  }

  Future<Set<String>> _readLocalUpvoteIds() async {
    final String? uid = _authState?.userId;
    if (uid == null || uid.isEmpty) {
      return <String>{};
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = prefs.getString('$_localUpvoteIdsPrefix$uid') ?? '';
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
    await prefs.setString('$_localUpvoteIdsPrefix$uid', jsonEncode(list));
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

  Future<SitesListResult> _mergeUpvotesIntoSitesList(
    SitesListResult result,
  ) async {
    final List<PollutionSite> sites = await _applyLocalUpvotePersistence(
      result.sites,
    );
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

  /// Saved feed rows must carry [PollutionSite.isSavedByMe] for cards and engagement.
  SitesListResult _withSavedSitesMarked(SitesListResult result) {
    if (result.sites.isEmpty) {
      return result;
    }
    bool changed = false;
    final List<PollutionSite> sites = <PollutionSite>[];
    for (final PollutionSite site in result.sites) {
      if (site.isSavedByMe) {
        sites.add(site);
      } else {
        changed = true;
        sites.add(site.copyWith(isSavedByMe: true));
      }
    }
    if (!changed) {
      return result;
    }
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
    final List<PollutionSite> merged = await _applyLocalUpvotePersistence(
      <PollutionSite>[site],
    );
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
    required String scope,
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
      scope,
      if (explain) '1' else '0',
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
    required String scope,
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
      scope,
      if (explain) '1' else '0',
    ].join('|');
  }

  String _savedFeedCacheKey({
    required double? latitude,
    required double? longitude,
    required int page,
    required int limit,
  }) {
    return [
      _feedAuthCacheSegment(),
      'saved',
      latitude?.toStringAsFixed(4) ?? '',
      longitude?.toStringAsFixed(4) ?? '',
      page.toString(),
      limit.toString(),
    ].join('|');
  }

  String _savedFeedScopeKey({
    required double? latitude,
    required double? longitude,
    required int limit,
  }) {
    return [
      _feedAuthCacheSegment(),
      'saved',
      latitude?.toStringAsFixed(4) ?? '',
      longitude?.toStringAsFixed(4) ?? '',
      limit.toString(),
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
        (safeAsStringKeyedMap(
                  safeAsStringKeyedMap(record.payload['meta']),
                )?['limit']
                as num?)
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
    final record = await _localCache.loadMapSnapshot(
      authSegment: _feedAuthCacheSegment(),
    );
    if (record == null) return null;
    final MapSitesResult parsed = _mapper.mapSitesResultFromPayload(
      record.payload,
      servedFromCache: true,
      cachedAt: record.cachedAt,
      isStaleFallback: true,
    );
    return parsed.sites.isEmpty ? null : parsed;
  }

  static const Set<String> _savedEndpointUnavailableCodes = <String>{
    'NOT_FOUND',
    'BAD_REQUEST',
    'VALIDATION_ERROR',
  };

  @override
  Future<SitesListResult> getSavedSites({
    int page = 1,
    int limit = 24,
    double? latitude,
    double? longitude,
  }) async {
    final List<String> queryParams = <String>['page=$page', 'limit=$limit'];
    if (latitude != null) queryParams.add('lat=$latitude');
    if (longitude != null) queryParams.add('lng=$longitude');
    final String path = '/sites/saved?${queryParams.join('&')}';
    final String cacheKey = _savedFeedCacheKey(
      latitude: latitude,
      longitude: longitude,
      page: page,
      limit: limit,
    );
    final String scopeKey = _savedFeedScopeKey(
      latitude: latitude,
      longitude: longitude,
      limit: limit,
    );
    final DateTime now = DateTime.now();
    try {
      final ApiResponse response = await _client.get(path);
      final Map<String, dynamic>? json = response.json;
      if (json == null) throw AppError.unknown();
      final SitesListResult parsed = _mapper.sitesListResultFromJson(
        json,
        page: page,
        limit: limit,
      );
      final SitesListResult result = _withSavedSitesMarked(
        await _mergeUpvotesIntoSitesList(
          SitesListResult(
            sites: parsed.sites,
            total: parsed.total,
            page: parsed.page,
            limit: parsed.limit,
            nextCursor: parsed.nextCursor,
            servedFromCache: false,
            isStaleFallback: false,
            cachedAt: now,
            lastSuccessfulRefreshAt: now,
            feedVariant: 'v1',
          ),
        ),
      );
      unawaited(
        _localCache.persistFeedSnapshot(
          scopeKey: scopeKey,
          requestKey: cacheKey,
          payload: json,
          now: now,
          page: page,
          cursor: null,
          nextCursor: result.nextCursor,
        ),
      );
      return result;
    } on AppError catch (e) {
      if (_savedEndpointUnavailableCodes.contains(e.code)) {
        AppLog.warn(
          'GET /sites/saved unavailable (${e.code}); showing empty saved list',
        );
        return SitesListResult.empty(page: page, limit: limit);
      }
      final SitesListResult? fallback = await _loadPersistedFeedSnapshot(
        requestKey: cacheKey,
        scopeKey: scopeKey,
        page: page,
      );
      if (fallback != null) {
        final DateTime fallbackCachedAt = fallback.cachedAt ?? now;
        final SitesListResult merged = _withSavedSitesMarked(
          await _mergeUpvotesIntoSitesList(fallback),
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
          lastSuccessfulRefreshAt: merged.lastSuccessfulRefreshAt,
          feedVariant: merged.feedVariant,
        );
      }
      rethrow;
    }
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
    String scope = 'local',
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
    queryParams.add('scope=$scope');
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
      scope: scope,
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
      scope: scope,
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
          response.headers['x-feed-variant']?.trim().isNotEmpty ?? false
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
        final SitesListResult merged = await _mergeUpvotesIntoSitesList(
          fallback,
        );
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
    double? zoom,
    String? status,
    bool includeArchived = false,
    bool prefetch = false,
  }) async {
    final double qLat = _snapMapGeoCenter(latitude);
    final double qLng = _snapMapGeoCenter(longitude);
    final double? qMinLat = _snapMapGeoMinEdge(minLatitude);
    final double? qMaxLat = _snapMapGeoMaxEdge(maxLatitude);
    final double? qMinLng = _snapMapGeoMinEdge(minLongitude);
    final double? qMaxLng = _snapMapGeoMaxEdge(maxLongitude);
    final String mapKey = [
      _feedAuthCacheSegment(),
      qLat.toStringAsFixed(4),
      qLng.toStringAsFixed(4),
      radiusKm.toStringAsFixed(1),
      limit.toString(),
      mapDetail,
      zoom?.toStringAsFixed(2) ?? '',
      status ?? '',
      if (includeArchived) '1' else '0',
      if (prefetch) 'p' else '',
      qMinLat?.toStringAsFixed(4) ?? '',
      qMaxLat?.toStringAsFixed(4) ?? '',
      qMinLng?.toStringAsFixed(4) ?? '',
      qMaxLng?.toStringAsFixed(4) ?? '',
    ].join('|');
    final DateTime now = DateTime.now();
    final ({MapSitesResult result, DateTime cachedAt})? mapMem =
        _memoryMapCache[mapKey];
    if (mapMem != null &&
        now.difference(mapMem.cachedAt) <= _mapMemoryCacheTtl) {
      final List<PollutionSite> merged = await _applyLocalUpvotePersistence(
        mapMem.result.sites,
      );
      return MapSitesResult(
        sites: merged,
        servedFromCache: true,
        cachedAt: mapMem.cachedAt,
        isStaleFallback: mapMem.result.isStaleFallback,
        signedMediaExpiresAt: mapMem.result.signedMediaExpiresAt,
      );
    }
    final List<String> queryParams = <String>[
      'lat=$qLat',
      'lng=$qLng',
      'radiusKm=$radiusKm',
      'limit=$limit',
      'detail=$mapDetail',
      if (zoom != null) 'zoom=$zoom',
      if (status != null && status.isNotEmpty) 'status=$status',
      if (includeArchived) 'includeArchived=true',
      if (prefetch) 'prefetch=true',
      if (qMinLat != null) 'minLat=$qMinLat',
      if (qMaxLat != null) 'maxLat=$qMaxLat',
      if (qMinLng != null) 'minLng=$qMinLng',
      if (qMaxLng != null) 'maxLng=$qMaxLng',
    ];
    try {
      final String? ifNoneMatch = _mapEtagCache[mapKey]?.etag;
      final ApiResponse response = await _client.get(
        '/sites/map?${queryParams.join('&')}',
        headers: ifNoneMatch == null
            ? null
            : <String, String>{'If-None-Match': ifNoneMatch},
      );
      Map<String, dynamic>? json = response.json;
      if (response.statusCode == 304) {
        json = _mapEtagCache[mapKey]?.payload;
      }
      if (json == null) {
        throw AppError.unknown(
          cause: 'Missing map payload for status ${response.statusCode}',
        );
      }
      final String? etagHeader = response.headers['etag'];
      if (etagHeader != null && etagHeader.isNotEmpty) {
        _mapEtagCache[mapKey] = (etag: etagHeader, payload: json);
      }
      unawaited(
        _localCache.persistMapSnapshot(
          json,
          authSegment: _feedAuthCacheSegment(),
        ),
      );
      final MapSitesResult parsed = _mapper.mapSitesResultFromPayload(json);
      final List<PollutionSite> merged = await _applyLocalUpvotePersistence(
        parsed.sites,
      );
      final MapSitesResult out = MapSitesResult(
        sites: merged,
        servedFromCache: parsed.servedFromCache,
        cachedAt: parsed.cachedAt,
        isStaleFallback: parsed.isStaleFallback,
        signedMediaExpiresAt: parsed.signedMediaExpiresAt,
      );
      _rememberMapMemoryEntry(
        mapKey,
        result: MapSitesResult(
          sites: List<PollutionSite>.from(merged),
          servedFromCache: out.servedFromCache,
          cachedAt: out.cachedAt,
          isStaleFallback: out.isStaleFallback,
          signedMediaExpiresAt: out.signedMediaExpiresAt,
        ),
        cachedAt: now,
      );
      return out;
    } on AppError catch (error) {
      if (!_shouldUsePersistedMapFallback(error)) {
        rethrow;
      }
      final MapSitesResult? fallback = await _loadPersistedMapSnapshot();
      if (fallback != null) {
        final List<PollutionSite> merged = await _applyLocalUpvotePersistence(
          fallback.sites,
        );
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

  bool _shouldUsePersistedMapFallback(AppError error) {
    switch (error.code) {
      case 'NETWORK_ERROR':
      case 'TIMEOUT':
      case 'SERVER_ERROR':
      case 'TOO_MANY_REQUESTS':
        return true;
      default:
        return false;
    }
  }

  @override
  Future<SiteMapSearchResponse> searchSitesForMap(
    SiteMapSearchRequest request, {
    RequestCancellationToken? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    final ApiResponse response = await _client.post(
      '/sites/search',
      body: request.toBodyJson(),
      cancellation: cancellation,
    );
    cancellation?.throwIfCancelled();
    final Map<String, dynamic>? json = response.json;
    if (json == null) {
      throw AppError.unknown(cause: 'Missing search response body');
    }
    return _mapper.siteMapSearchResponseFromJson(json);
  }

  @override
  Future<PollutionSite?> getSiteById(String id) {
    return _inFlightSiteById.putIfAbsent(id, () {
      final Future<PollutionSite?> future = _fetchSiteById(id);
      unawaited(
        future.whenComplete(() {
          if (_inFlightSiteById[id] == future) {
            _inFlightSiteById.remove(id);
          }
        }),
      );
      return future;
    });
  }

  Future<PollutionSite?> _fetchSiteById(String id) async {
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
