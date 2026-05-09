import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:chisto_mobile/core/connectivity/connectivity_checker.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/home/data/offline_regions/offline_region_model.dart';
import 'package:chisto_mobile/features/home/data/offline_regions/offline_region_store.dart';
import 'package:chisto_mobile/features/home/data/sites_json_mapper.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository.dart';

import 'map_site_event.dart';
import 'map_sync_inline_notice.dart';

/// Set `--dart-define=MAP_SYNC_PERF=true` to log full-map sync timing in debug builds.
const bool _kMapSyncPerfLogs = bool.fromEnvironment(
  'MAP_SYNC_PERF',
  defaultValue: false,
);

class MapViewportQuery {
  const MapViewportQuery({
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.limit,
    required this.zoom,
    this.includeArchived = false,
    this.minLatitude,
    this.maxLatitude,
    this.minLongitude,
    this.maxLongitude,
  });

  final double latitude;
  final double longitude;
  final double radiusKm;
  final int limit;
  final double zoom;
  final bool includeArchived;
  final double? minLatitude;
  final double? maxLatitude;
  final double? minLongitude;
  final double? maxLongitude;

  bool get hasBounds =>
      minLatitude != null &&
      maxLatitude != null &&
      minLongitude != null &&
      maxLongitude != null;

  String get cacheKey => <String>[
    latitude.toStringAsFixed(4),
    longitude.toStringAsFixed(4),
    radiusKm.toStringAsFixed(1),
    limit.toString(),
    zoom.toStringAsFixed(2),
    includeArchived ? '1' : '0',
    minLatitude?.toStringAsFixed(4) ?? '',
    maxLatitude?.toStringAsFixed(4) ?? '',
    minLongitude?.toStringAsFixed(4) ?? '',
    maxLongitude?.toStringAsFixed(4) ?? '',
  ].join('|');

  bool containsSite(PollutionSite site) {
    return containsCoordinates(site.latitude, site.longitude);
  }

  bool containsCoordinates(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) {
      return false;
    }
    if (hasBounds) {
      return latitude >= minLatitude! &&
          latitude <= maxLatitude! &&
          longitude >= minLongitude! &&
          longitude <= maxLongitude!;
    }
    if (radiusKm <= 0) {
      return true;
    }
    return distanceKmBetween(this.latitude, this.longitude, latitude, longitude) <=
        radiusKm;
  }

  /// Geodesic distance in kilometers (haversine).
  static double distanceKmBetween(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    final double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) =>
      degrees * 0.017453292519943295;

  /// Shifts center and optional bbox by fixed deltas (degrees). Used for predictive prefetch.
  MapViewportQuery shiftedBy({
    required double deltaLatDegrees,
    required double deltaLngDegrees,
  }) {
    return MapViewportQuery(
      latitude: latitude + deltaLatDegrees,
      longitude: longitude + deltaLngDegrees,
      radiusKm: radiusKm,
      limit: limit,
      zoom: zoom,
      includeArchived: includeArchived,
      minLatitude: minLatitude != null ? minLatitude! + deltaLatDegrees : null,
      maxLatitude: maxLatitude != null ? maxLatitude! + deltaLatDegrees : null,
      minLongitude: minLongitude != null ? minLongitude! + deltaLngDegrees : null,
      maxLongitude: maxLongitude != null ? maxLongitude! + deltaLngDegrees : null,
    );
  }

  /// True when [inner]'s viewport bbox lies fully inside this query's bbox.
  /// Used to skip redundant map fetches while the camera stays within the
  /// last server query envelope (overscanned bounds).
  bool containsViewport(MapViewportQuery inner) {
    if (!hasBounds || !inner.hasBounds) {
      return false;
    }
    if (includeArchived != inner.includeArchived || limit != inner.limit) {
      return false;
    }
    if ((radiusKm - inner.radiusKm).abs() > 0.05) {
      return false;
    }
    return minLatitude! <= inner.minLatitude! &&
        maxLatitude! >= inner.maxLatitude! &&
        minLongitude! <= inner.minLongitude! &&
        maxLongitude! >= inner.maxLongitude!;
  }

  /// True when this viewport's bbox overlaps [region]'s saved bbox (axis-aligned).
  bool intersectsOfflineRegion(OfflineRegion region) {
    if (!hasBounds) {
      return false;
    }
    return !(maxLatitude! < region.minLat ||
        minLatitude! > region.maxLat ||
        maxLongitude! < region.minLng ||
        minLongitude! > region.maxLng);
  }
}

class MapSyncSnapshot {
  const MapSyncSnapshot({
    this.sites = const <PollutionSite>[],
    this.loadError,
    this.inlineNotice,
    this.lastSuccessfulSyncAt,
    this.cachedAt,
    this.isUsingPersistedFallback = false,
  });

  final List<PollutionSite> sites;
  final AppError? loadError;
  final MapSyncInlineNotice? inlineNotice;
  final DateTime? lastSuccessfulSyncAt;
  final DateTime? cachedAt;
  final bool isUsingPersistedFallback;

  MapSyncSnapshot copyWith({
    List<PollutionSite>? sites,
    AppError? loadError,
    bool clearLoadError = false,
    MapSyncInlineNotice? inlineNotice,
    bool clearInlineNotice = false,
    DateTime? lastSuccessfulSyncAt,
    DateTime? cachedAt,
    bool? isUsingPersistedFallback,
  }) {
    return MapSyncSnapshot(
      sites: sites ?? this.sites,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      inlineNotice: clearInlineNotice
          ? null
          : (inlineNotice ?? this.inlineNotice),
      lastSuccessfulSyncAt: lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
      cachedAt: cachedAt ?? this.cachedAt,
      isUsingPersistedFallback:
          isUsingPersistedFallback ?? this.isUsingPersistedFallback,
    );
  }
}

class MapSyncCoordinator extends ChangeNotifier {
  MapSyncCoordinator({
    required SitesRepository sitesRepository,
    OfflineRegionStore? offlineRegionStore,
    ConnectivityChecker? connectivityChecker,
    SitesJsonMapper jsonMapper = const SitesJsonMapper(),
  })  : _sitesRepository = sitesRepository,
        _offlineRegionStore = offlineRegionStore,
        _connectivityChecker = connectivityChecker ?? ConnectivityChecker.system(),
        _jsonMapper = jsonMapper;

  static const int _maxRecentEventIds = 300;

  final SitesRepository _sitesRepository;
  final OfflineRegionStore? _offlineRegionStore;
  final ConnectivityChecker _connectivityChecker;
  final SitesJsonMapper _jsonMapper;

  MapSyncSnapshot _snapshot = const MapSyncSnapshot();
  MapViewportQuery? _currentQuery;
  Timer? _fullSyncDebounce;
  /// Backoff retry after HTTP 429 — must not share [_fullSyncDebounce] or
  /// normal debounced [requestSync] calls cancel the retry timer.
  Timer? _mapRateLimitRetryTimer;
  Timer? _signedMediaRefreshTimer;
  bool _fullSyncInFlight = false;
  bool _fullSyncPending = false;
  bool _active = true;
  int _requestGeneration = 0;
  /// Avoids tight loops when [MapSitesResult.signedMediaExpiresAt] stays in the past.
  bool _usedImmediateSignedMediaRefreshWhileExpired = false;
  final Set<String> _pendingSiteIds = <String>{};
  final Set<String> _singleSiteFetchesInFlight = <String>{};
  final Set<String> _recentEventIds = <String>{};
  final ListQueue<String> _recentEventQueue = ListQueue<String>();

  /// Last query that produced a successful network map response (envelope).
  MapViewportQuery? _lastFetchedQuery;
  DateTime? _lastFetchedAt;

  /// After HTTP 429, block map fetches until this instant (server / Retry-After).
  DateTime? _mapRateLimitUntil;

  /// Limits predictive prefetch frequency so pan inertia does not parallel the
  /// main map sync and amplify 429s from the same rate-limit bucket.
  DateTime? _lastPrefetchStartedAt;
  static const Duration _prefetchMinInterval = Duration(seconds: 12);

  static const Duration _envelopeFreshnessTtl = Duration(seconds: 30);
  static const double _zoomHysteresis = 0.8;

  static const int _maxPanSamples = 4;
  final List<_PanSample> _panSamples = <_PanSample>[];
  int _prefetchEpoch = 0;

  MapSyncSnapshot get snapshot => _snapshot;

  void _releaseExpiredMapRateLimitIfNeeded() {
    final DateTime? until = _mapRateLimitUntil;
    if (until != null && !DateTime.now().isBefore(until)) {
      _mapRateLimitUntil = null;
    }
  }

  bool get _isMapRateLimited {
    final DateTime? until = _mapRateLimitUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  void _applyMapRateLimitFromError(AppError error) {
    if (error.code != 'TOO_MANY_REQUESTS') {
      return;
    }
    int seconds = 25;
    final Object? details = error.details;
    if (details is Map) {
      final Object? retryAfter = details['retryAfterSeconds'];
      if (retryAfter is int) {
        seconds = retryAfter.clamp(5, 120);
      } else {
        final Object? ttl = details['ttlSeconds'];
        if (ttl is int) {
          seconds = ttl.clamp(5, 120);
        }
      }
    }
    _mapRateLimitUntil = DateTime.now().add(Duration(seconds: seconds));
  }

  void _scheduleDeferredSyncAfterMapRateLimit() {
    final DateTime? until = _mapRateLimitUntil;
    if (until == null) {
      return;
    }
    final Duration wait = until.difference(DateTime.now());
    _mapRateLimitRetryTimer?.cancel();
    final Duration fireIn = wait <= Duration.zero
        ? const Duration(milliseconds: 200)
        : wait + const Duration(milliseconds: 250);
    _mapRateLimitRetryTimer = Timer(fireIn, () {
      _mapRateLimitRetryTimer = null;
      requestSync(immediate: false);
    });
  }

  /// Call after a pan gesture completes; may warm HTTP/cache for the likely next viewport.
  void schedulePredictivePrefetchFromPan({
    required double centerLat,
    required double centerLng,
    required double zoom,
  }) {
    if (zoom < 3.5) {
      return;
    }
    if (!_active ||
        _currentQuery == null ||
        _fullSyncInFlight ||
        _isMapRateLimited) {
      return;
    }
    final DateTime now = DateTime.now();
    _panSamples.add(_PanSample(centerLat, centerLng, now));
    while (_panSamples.length > _maxPanSamples) {
      _panSamples.removeAt(0);
    }
    if (_panSamples.length < 2) {
      return;
    }
    final _PanSample a = _panSamples[_panSamples.length - 2];
    final _PanSample b = _panSamples[_panSamples.length - 1];
    final double dtSec = b.t.difference(a.t).inMilliseconds / 1000.0;
    if (dtSec <= 0.01) {
      return;
    }
    final double distKm = MapViewportQuery.distanceKmBetween(
      a.lat,
      a.lng,
      b.lat,
      b.lng,
    );
    if (distKm < 0.08 || distKm / dtSec < 0.12) {
      return;
    }
    double dLat = b.lat - a.lat;
    double dLng = b.lng - a.lng;
    final double flat = cos(b.lat * pi / 180);
    final double len = sqrt(dLat * dLat + dLng * dLng);
    if (len < 1e-8) {
      return;
    }
    dLat /= len;
    dLng /= len;
    const double lookaheadKm = 2.5;
    const double kmToLat = 1.0 / 111.0;
    final double kmToLng = 1.0 / (111.0 * max(0.2, flat.abs()));
    final MapViewportQuery shifted = _currentQuery!.shiftedBy(
      deltaLatDegrees: dLat * lookaheadKm * kmToLat,
      deltaLngDegrees: dLng * lookaheadKm * kmToLng,
    );
    _prefetchEpoch++;
    final int epoch = _prefetchEpoch;
    unawaited(_runPrefetchWarmCache(epoch, shifted));
  }

  Future<void> _runPrefetchWarmCache(int epoch, MapViewportQuery q) async {
    if (_isMapRateLimited) {
      return;
    }
    final DateTime now = DateTime.now();
    if (_lastPrefetchStartedAt != null &&
        now.difference(_lastPrefetchStartedAt!) < _prefetchMinInterval) {
      return;
    }
    _lastPrefetchStartedAt = now;
    try {
      await _sitesRepository.getSitesForMap(
        latitude: q.latitude,
        longitude: q.longitude,
        radiusKm: q.radiusKm,
        limit: q.limit,
        minLatitude: q.minLatitude,
        maxLatitude: q.maxLatitude,
        minLongitude: q.minLongitude,
        maxLongitude: q.maxLongitude,
        mapDetail: SitesRepository.mapDetailLite,
        zoom: q.zoom,
        includeArchived: q.includeArchived,
        prefetch: true,
      );
    } catch (_) {
      // Prefetch is best-effort only.
    }
    if (epoch != _prefetchEpoch) {
      return;
    }
  }

  void updateViewport(MapViewportQuery query) {
    _currentQuery = query;
  }

  void setActive(bool active) {
    if (_active == active) {
      return;
    }
    _active = active;
    _requestGeneration += 1;
    if (!active) {
      _fullSyncDebounce?.cancel();
      _signedMediaRefreshTimer?.cancel();
      _signedMediaRefreshTimer = null;
      return;
    }
    final DateTime? lastSuccess = _snapshot.lastSuccessfulSyncAt;
    final bool shouldReconcile =
        lastSuccess == null ||
        DateTime.now().difference(lastSuccess) > const Duration(seconds: 45);
    if (shouldReconcile) {
      requestSync(immediate: true);
    }
  }

  bool rememberRealtimeEvent(String eventId) {
    if (_recentEventIds.contains(eventId)) {
      return false;
    }
    _recentEventIds.add(eventId);
    _recentEventQueue.addLast(eventId);
    while (_recentEventQueue.length > _maxRecentEventIds) {
      final String oldest = _recentEventQueue.removeFirst();
      _recentEventIds.remove(oldest);
    }
    return true;
  }

  void ingestEvent(MapSiteEvent event) {
    if (!_active || !rememberRealtimeEvent(event.eventId)) {
      return;
    }
    _pendingSiteIds.add(event.siteId);
    if (event.latitude != null && event.longitude != null) {
      unawaited(_refreshSingleSite(event.siteId));
    }
    requestSync(immediate: event.type == 'site_created');
  }

  void requestSync({required bool immediate}) {
    if (!_active || _currentQuery == null) {
      return;
    }
    _releaseExpiredMapRateLimitIfNeeded();
    if (_fullSyncInFlight) {
      _fullSyncPending = true;
      return;
    }
    if (_isMapRateLimited) {
      _scheduleDeferredSyncAfterMapRateLimit();
      return;
    }
    if (immediate) {
      _fullSyncDebounce?.cancel();
      unawaited(_performFullSync(allowEnvelopeSkip: false));
      return;
    }
    final DateTime now = DateTime.now();
    final int sinceLastMs = _snapshot.lastSuccessfulSyncAt == null
        ? 9999
        : now.difference(_snapshot.lastSuccessfulSyncAt!).inMilliseconds;
    final int minIntervalMs = _pendingSiteIds.length > 8 ? 900 : 500;
    final int delayMs = sinceLastMs >= minIntervalMs
        ? 350
        : (minIntervalMs - sinceLastMs + 120).clamp(200, 1200);
    _fullSyncDebounce?.cancel();
    _fullSyncDebounce = Timer(Duration(milliseconds: delayMs), () {
      unawaited(_performFullSync(allowEnvelopeSkip: true));
    });
  }

  bool _shouldSkipFetchForEnvelope(
    MapViewportQuery query, {
    required bool allowEnvelopeSkip,
  }) {
    if (!allowEnvelopeSkip) {
      return false;
    }
    if (_lastFetchedQuery == null || _lastFetchedAt == null) {
      return false;
    }
    if (_snapshot.sites.isEmpty) {
      return false;
    }
    if (_pendingSiteIds.isNotEmpty) {
      return false;
    }
    if (_lastFetchedQuery!.includeArchived != query.includeArchived) {
      return false;
    }
    if (_lastFetchedQuery!.limit != query.limit) {
      return false;
    }
    if (DateTime.now().difference(_lastFetchedAt!) > _envelopeFreshnessTtl) {
      return false;
    }
    if ((query.zoom - _lastFetchedQuery!.zoom).abs() > _zoomHysteresis) {
      return false;
    }
    return _lastFetchedQuery!.containsViewport(query);
  }

  /// When offline, returns cached `/sites/map` JSON from a saved region that
  /// intersects the viewport; otherwise null (caller uses network).
  Future<MapSitesResult?> _tryLoadOfflineRegionSites(
    MapViewportQuery query,
  ) async {
    final OfflineRegionStore? store = _offlineRegionStore;
    if (store == null || !store.isInitialized) {
      return null;
    }
    if (!await _connectivityChecker.isOffline()) {
      return null;
    }
    if (!query.hasBounds) {
      return null;
    }
    try {
      for (final OfflineRegion region in store.getRegions()) {
        if (!query.intersectsOfflineRegion(region)) {
          continue;
        }
        final String? jsonStr = store.getSitesJson(region.id);
        if (jsonStr == null || jsonStr.isEmpty) {
          continue;
        }
        final Object? decoded = jsonDecode(jsonStr);
        if (decoded is! Map<String, dynamic>) {
          continue;
        }
        return _jsonMapper.mapSitesResultFromPayload(
          decoded,
          servedFromCache: true,
          cachedAt: region.lastRefreshed,
          isStaleFallback: true,
        );
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[MapSync] offline region parse failed: $e');
      }
    }
    return null;
  }

  Future<void> _performFullSync({bool allowEnvelopeSkip = true}) async {
    final MapViewportQuery? query = _currentQuery;
    if (!_active || query == null) {
      return;
    }
    _releaseExpiredMapRateLimitIfNeeded();
    if (_isMapRateLimited) {
      _scheduleDeferredSyncAfterMapRateLimit();
      return;
    }
    if (_fullSyncInFlight) {
      _fullSyncPending = true;
      return;
    }
    if (_shouldSkipFetchForEnvelope(query, allowEnvelopeSkip: allowEnvelopeSkip)) {
      if (kDebugMode && _kMapSyncPerfLogs) {
        debugPrint('[MapSync] skip full sync (viewport inside envelope)');
      }
      return;
    }
    _fullSyncInFlight = true;
    final int generation = _requestGeneration;
    final Stopwatch sw = Stopwatch()..start();
    try {
      final MapSitesResult? offlineResult =
          await _tryLoadOfflineRegionSites(query);
      final MapSitesResult result = offlineResult ??
          await _sitesRepository.getSitesForMap(
            latitude: query.latitude,
            longitude: query.longitude,
            radiusKm: query.radiusKm,
            limit: query.limit,
            minLatitude: query.minLatitude,
            maxLatitude: query.maxLatitude,
            minLongitude: query.minLongitude,
            maxLongitude: query.maxLongitude,
            mapDetail: SitesRepository.mapDetailLite,
            zoom: query.zoom,
            includeArchived: query.includeArchived,
          );
      if (!_active || generation != _requestGeneration) {
        return;
      }
      if (kDebugMode && _kMapSyncPerfLogs) {
        debugPrint(
          '[MapSync] full sync ${sw.elapsedMilliseconds}ms '
          'sites=${result.sites.length}',
        );
      }
      _mapRateLimitUntil = null;
      _lastFetchedQuery = query;
      _lastFetchedAt = DateTime.now();
      _pendingSiteIds.clear();
      _setSnapshot(
        _snapshot.copyWith(
          sites: result.sites,
          clearLoadError: true,
          clearInlineNotice: !result.servedFromCache,
          inlineNotice: result.isStaleFallback
              ? MapSyncInlineNotice.offlineCached(cachedAt: result.cachedAt)
              : null,
          lastSuccessfulSyncAt: DateTime.now(),
          cachedAt: result.cachedAt,
          isUsingPersistedFallback: result.isStaleFallback,
        ),
      );
      if (result.isStaleFallback) {
        _signedMediaRefreshTimer?.cancel();
        _signedMediaRefreshTimer = null;
      } else {
        _scheduleSignedMediaRefresh(result.signedMediaExpiresAt);
      }
    } on AppError catch (error) {
      if (!_active || generation != _requestGeneration) {
        return;
      }
      _applyMapRateLimitFromError(error);
      final bool rateLimited = error.code == 'TOO_MANY_REQUESTS';
      if (_snapshot.sites.isEmpty) {
        if (rateLimited) {
          // Keep map usable: never block the canvas on map rate limits; banner + backoff only.
          _setSnapshot(
            _snapshot.copyWith(
              clearLoadError: true,
              inlineNotice: const MapSyncInlineNotice.liveUpdatesDelayed(),
            ),
          );
        } else {
          _setSnapshot(
            _snapshot.copyWith(
              loadError: error,
              inlineNotice: null,
              clearInlineNotice: true,
            ),
          );
        }
      } else {
        final bool connectivityLike = _isConnectivityLikeMapError(error);
        _setSnapshot(
          _snapshot.copyWith(
            clearLoadError: true,
            inlineNotice: connectivityLike
                ? const MapSyncInlineNotice.liveUpdatesDelayed()
                : null,
            clearInlineNotice: !connectivityLike,
          ),
        );
      }
      if (rateLimited) {
        _scheduleDeferredSyncAfterMapRateLimit();
      }
    } catch (error) {
      if (!_active || generation != _requestGeneration) {
        return;
      }
      final AppError appError = AppError.network(cause: error);
      if (_snapshot.sites.isEmpty) {
        _setSnapshot(
          _snapshot.copyWith(
            loadError: appError,
            inlineNotice: null,
            clearInlineNotice: true,
          ),
        );
      } else {
        _setSnapshot(
          _snapshot.copyWith(
            clearLoadError: true,
            inlineNotice: const MapSyncInlineNotice.connectionUnstable(),
          ),
        );
      }
    } finally {
      _fullSyncInFlight = false;
      if (_fullSyncPending) {
        _fullSyncPending = false;
        requestSync(immediate: false);
      }
    }
  }

  bool _isConnectivityLikeMapError(AppError error) {
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

  /// Refreshes map payload so presigned report thumbnails stay valid (see API `meta.signedMediaExpiresAt`).
  void _scheduleSignedMediaRefresh(DateTime? expiresAt) {
    _signedMediaRefreshTimer?.cancel();
    _signedMediaRefreshTimer = null;
    if (expiresAt == null || !_active) {
      return;
    }
    final DateTime now = DateTime.now();
    if (expiresAt.isAfter(now)) {
      _usedImmediateSignedMediaRefreshWhileExpired = false;
    }
    final DateTime trigger = expiresAt.subtract(const Duration(minutes: 5));
    final Duration delay = trigger.difference(now);
    void fire() {
      if (!_active || _currentQuery == null) {
        return;
      }
      requestSync(immediate: true);
    }

    if (delay <= Duration.zero) {
      if (!_usedImmediateSignedMediaRefreshWhileExpired) {
        _usedImmediateSignedMediaRefreshWhileExpired = true;
        scheduleMicrotask(fire);
        return;
      }
      _signedMediaRefreshTimer = Timer(const Duration(seconds: 2), fire);
      return;
    }
    _signedMediaRefreshTimer = Timer(delay, fire);
  }

  Future<void> _refreshSingleSite(String siteId) async {
    final MapViewportQuery? query = _currentQuery;
    if (!_active ||
        query == null ||
        _singleSiteFetchesInFlight.contains(siteId)) {
      return;
    }
    _singleSiteFetchesInFlight.add(siteId);
    final int generation = _requestGeneration;
    try {
      final PollutionSite? site = await _sitesRepository.getSiteById(siteId);
      if (!_active || generation != _requestGeneration) {
        return;
      }
      final List<PollutionSite> next = <PollutionSite>[..._snapshot.sites];
      final int existingIndex = next.indexWhere(
        (PollutionSite item) => item.id == siteId,
      );
      if (site == null || !query.containsSite(site)) {
        if (existingIndex >= 0) {
          next.removeAt(existingIndex);
          _setSnapshot(_snapshot.copyWith(sites: next, clearLoadError: true));
        }
        return;
      }
      if (existingIndex >= 0) {
        next[existingIndex] = site;
      } else {
        next.insert(0, site);
      }
      _setSnapshot(_snapshot.copyWith(sites: next, clearLoadError: true));
    } catch (_) {
      // Full reconcile still runs shortly after the incremental fetch path.
    } finally {
      _singleSiteFetchesInFlight.remove(siteId);
    }
  }

  void _setSnapshot(MapSyncSnapshot next) {
    if (listEquals(_snapshot.sites, next.sites) &&
        _snapshot.loadError == next.loadError &&
        _snapshot.inlineNotice == next.inlineNotice &&
        _snapshot.lastSuccessfulSyncAt == next.lastSuccessfulSyncAt &&
        _snapshot.cachedAt == next.cachedAt &&
        _snapshot.isUsingPersistedFallback == next.isUsingPersistedFallback) {
      return;
    }
    _snapshot = next;
    notifyListeners();
  }

  /// Inserts or replaces a site (e.g. deep-link focus fetched [getSiteById] before viewport sync includes it).
  void upsertSite(PollutionSite site) {
    final List<PollutionSite> next = <PollutionSite>[..._snapshot.sites];
    final int i = next.indexWhere((PollutionSite s) => s.id == site.id);
    if (i >= 0) {
      next[i] = site;
    } else {
      next.insert(0, site);
    }
    _setSnapshot(_snapshot.copyWith(sites: next, clearLoadError: true));
  }

  @override
  void dispose() {
    _requestGeneration += 1;
    _fullSyncDebounce?.cancel();
    _mapRateLimitRetryTimer?.cancel();
    _mapRateLimitRetryTimer = null;
    _signedMediaRefreshTimer?.cancel();
    _panSamples.clear();
    super.dispose();
  }
}

class _PanSample {
  _PanSample(this.lat, this.lng, this.t);

  final double lat;
  final double lng;
  final DateTime t;
}
