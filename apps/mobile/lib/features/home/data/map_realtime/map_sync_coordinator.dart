import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository.dart';

import 'map_site_event.dart';

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
    this.minLatitude,
    this.maxLatitude,
    this.minLongitude,
    this.maxLongitude,
  });

  final double latitude;
  final double longitude;
  final double radiusKm;
  final int limit;
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
    return _distanceKm(this.latitude, this.longitude, latitude, longitude) <=
        radiusKm;
  }

  static double _distanceKm(
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
  final String? inlineNotice;
  final DateTime? lastSuccessfulSyncAt;
  final DateTime? cachedAt;
  final bool isUsingPersistedFallback;

  MapSyncSnapshot copyWith({
    List<PollutionSite>? sites,
    AppError? loadError,
    bool clearLoadError = false,
    String? inlineNotice,
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
  MapSyncCoordinator({required SitesRepository sitesRepository})
    : _sitesRepository = sitesRepository;

  static const int _maxRecentEventIds = 300;

  final SitesRepository _sitesRepository;

  MapSyncSnapshot _snapshot = const MapSyncSnapshot();
  MapViewportQuery? _currentQuery;
  Timer? _fullSyncDebounce;
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

  MapSyncSnapshot get snapshot => _snapshot;

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
    if (_fullSyncInFlight) {
      _fullSyncPending = true;
      return;
    }
    if (immediate) {
      _fullSyncDebounce?.cancel();
      unawaited(_performFullSync());
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
      unawaited(_performFullSync());
    });
  }

  Future<void> _performFullSync() async {
    final MapViewportQuery? query = _currentQuery;
    if (!_active || query == null) {
      return;
    }
    if (_fullSyncInFlight) {
      _fullSyncPending = true;
      return;
    }
    _fullSyncInFlight = true;
    final int generation = _requestGeneration;
    final Stopwatch sw = Stopwatch()..start();
    try {
      final MapSitesResult result = await _sitesRepository.getSitesForMap(
        latitude: query.latitude,
        longitude: query.longitude,
        radiusKm: query.radiusKm,
        limit: query.limit,
        minLatitude: query.minLatitude,
        maxLatitude: query.maxLatitude,
        minLongitude: query.minLongitude,
        maxLongitude: query.maxLongitude,
        mapDetail: SitesRepository.mapDetailLite,
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
      _pendingSiteIds.clear();
      _setSnapshot(
        _snapshot.copyWith(
          sites: result.sites,
          clearLoadError: true,
          clearInlineNotice: !result.servedFromCache,
          inlineNotice: result.isStaleFallback
              ? _fallbackNotice(result.cachedAt)
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
      if (_snapshot.sites.isEmpty) {
        _setSnapshot(
          _snapshot.copyWith(
            loadError: error,
            inlineNotice: null,
            clearInlineNotice: true,
          ),
        );
      } else {
        _setSnapshot(
          _snapshot.copyWith(
            clearLoadError: true,
            inlineNotice: 'Live updates delayed. Retrying quietly…',
          ),
        );
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
            inlineNotice: 'Connection unstable. Refreshing in background…',
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

  String _fallbackNotice(DateTime? cachedAt) {
    if (cachedAt == null) {
      return 'Offline. Showing your last saved map snapshot.';
    }
    final Duration age = DateTime.now().difference(cachedAt);
    if (age.inMinutes < 1) {
      return 'Offline. Showing your last saved map snapshot from just now.';
    }
    if (age.inHours < 1) {
      return 'Offline. Showing your last saved map snapshot from ${age.inMinutes}m ago.';
    }
    return 'Offline. Showing your last saved map snapshot from ${age.inHours}h ago.';
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

  @override
  void dispose() {
    _requestGeneration += 1;
    _fullSyncDebounce?.cancel();
    _signedMediaRefreshTimer?.cancel();
    super.dispose();
  }
}
