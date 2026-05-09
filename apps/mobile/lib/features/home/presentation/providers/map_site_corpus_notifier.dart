import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/home/data/map_regions/macedonia_map_regions.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository.dart';
import 'package:chisto_mobile/features/home/data/sites_json_mapper.dart';
import 'package:chisto_mobile/features/home/data/sites_local_cache.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_filter_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/providers/repository_providers.dart';
import 'package:chisto_mobile/features/home/presentation/utils/map_site_filter.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';

/// Max sites kept in memory for search prefetch (server map cap is lower; this caps merges).
const int kMapSiteCorpusMaxSites = 2500;

/// Debounce after filter edits before hitting the map API for corpus refresh.
const Duration kMapSiteCorpusDebounce = Duration(milliseconds: 520);

/// Backoff after rate-limit before retrying corpus fetch.
const Duration kMapSiteCorpusRateLimitBackoff = Duration(seconds: 18);

class MapSiteCorpusState {
  const MapSiteCorpusState({
    this.sites = const <PollutionSite>[],
    this.isRefreshing = false,
    this.lastError,
    this.lastFetchedAt,
    this.rateLimitedUntil,
  });

  final List<PollutionSite> sites;
  final bool isRefreshing;
  final Object? lastError;
  final DateTime? lastFetchedAt;
  final DateTime? rateLimitedUntil;

  MapSiteCorpusState copyWith({
    List<PollutionSite>? sites,
    bool? isRefreshing,
    Object? lastError,
    bool clearError = false,
    DateTime? lastFetchedAt,
    DateTime? rateLimitedUntil,
    bool clearRateLimit = false,
  }) {
    return MapSiteCorpusState(
      sites: sites ?? this.sites,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      rateLimitedUntil:
          clearRateLimit ? null : (rateLimitedUntil ?? this.rateLimitedUntil),
    );
  }
}

final mapSiteCorpusNotifierProvider =
    NotifierProvider<MapSiteCorpusNotifier, MapSiteCorpusState>(
  MapSiteCorpusNotifier.new,
);

class MapSiteCorpusNotifier extends Notifier<MapSiteCorpusState> {
  Timer? _debounce;
  int _generation = 0;

  @override
  MapSiteCorpusState build() {
    ref.listen<MapFilterState>(
      mapFilterNotifierProvider,
      (MapFilterState? previous, MapFilterState next) {
        if (previous == null) {
          _scheduleFetch(next);
          return;
        }
        if (MapFilterState.expansionResetKey(previous) ==
            MapFilterState.expansionResetKey(next)) {
          return;
        }
        _scheduleFetch(next);
      },
    );
    ref.onDispose(() {
      _debounce?.cancel();
    });
    Future<void>.microtask(() => _tryRestoreFromDisk());
    return const MapSiteCorpusState();
  }

  Future<void> _tryRestoreFromDisk() async {
    final MapFilterState filter = ref.read(mapFilterNotifierProvider);
    final int key = MapFilterState.expansionResetKey(filter);
    final SitesLocalCache cache = SitesLocalCache();
    final ({int filterKey, List<Map<String, dynamic>> sites})? loaded =
        await cache.loadMapCorpus();
    if (loaded == null || loaded.filterKey != key) {
      return;
    }
    if (MapFilterState.expansionResetKey(ref.read(mapFilterNotifierProvider)) !=
        key) {
      return;
    }
    const SitesJsonMapper mapper = SitesJsonMapper();
    final LatLngBounds? geoBounds =
        MacedoniaMapRegions.boundsFor(filter.geoAreaId);
    final List<PollutionSite> sites = loaded.sites
        .map(mapper.siteListItemFromJson)
        .where(
          (PollutionSite s) =>
              pollutionSiteMatchesMapFilter(s, filter, geoBounds: geoBounds),
        )
        .take(kMapSiteCorpusMaxSites)
        .toList();
    state = MapSiteCorpusState(
      sites: sites,
      lastFetchedAt: DateTime.now(),
    );
  }

  void _scheduleFetch(MapFilterState filter) {
    _debounce?.cancel();
    _debounce = Timer(kMapSiteCorpusDebounce, () {
      unawaited(_fetchCorpus(filter));
    });
  }

  Future<void> _fetchCorpus(MapFilterState filter) async {
    final int gen = ++_generation;
    final DateTime? rl = state.rateLimitedUntil;
    if (rl != null && DateTime.now().isBefore(rl)) {
      return;
    }
    state = state.copyWith(isRefreshing: true, clearError: true);

    final LatLngBounds bounds = MacedoniaMapRegions.boundsFor(filter.geoAreaId) ??
        LatLngBounds(
          LatLng(ReportGeoFence.minLat, ReportGeoFence.minLng),
          LatLng(ReportGeoFence.maxLat, ReportGeoFence.maxLng),
        );

    final double minLat = bounds.south;
    final double maxLat = bounds.north;
    final double minLng = bounds.west;
    final double maxLng = bounds.east;
    final double centerLat = (minLat + maxLat) / 2;
    final double centerLng = (minLng + maxLng) / 2;

    final SitesRepository repo = ref.read(sitesRepositoryProvider);
    try {
      final result = await repo.getSitesForMap(
        latitude: centerLat,
        longitude: centerLng,
        radiusKm: 500,
        minLatitude: minLat,
        maxLatitude: maxLat,
        minLongitude: minLng,
        maxLongitude: maxLng,
        mapDetail: SitesRepository.mapDetailLite,
        zoom: 15,
        includeArchived: filter.includeArchived,
        prefetch: true,
      );
      if (gen != _generation) {
        return;
      }
      final LatLngBounds? geoBounds =
          MacedoniaMapRegions.boundsFor(filter.geoAreaId);
      final List<PollutionSite> filtered = result.sites
          .where(
            (PollutionSite s) =>
                pollutionSiteMatchesMapFilter(s, filter, geoBounds: geoBounds),
          )
          .take(kMapSiteCorpusMaxSites)
          .toList();
      state = MapSiteCorpusState(
        sites: filtered,
        isRefreshing: false,
        lastFetchedAt: DateTime.now(),
        lastError: null,
        rateLimitedUntil: null,
      );
      final int persistKey = MapFilterState.expansionResetKey(filter);
      const SitesJsonMapper mapper = SitesJsonMapper();
      unawaited(
        SitesLocalCache().persistMapCorpus(
          filterKey: persistKey,
          sites: filtered.map(mapper.siteListItemToJson).toList(),
        ),
      );
    } on AppError catch (e) {
      if (gen != _generation) {
        return;
      }
      if (e.code == 'TOO_MANY_REQUESTS') {
        state = state.copyWith(
          isRefreshing: false,
          lastError: e,
          rateLimitedUntil:
              DateTime.now().add(kMapSiteCorpusRateLimitBackoff),
        );
        return;
      }
      state = state.copyWith(isRefreshing: false, lastError: e);
    } catch (e) {
      if (gen != _generation) {
        return;
      }
      state = state.copyWith(isRefreshing: false, lastError: e);
    }
  }

  /// Manual refresh (e.g. pull-to-refresh on search sheet — optional hook).
  Future<void> refresh() async {
    await _fetchCorpus(ref.read(mapFilterNotifierProvider));
  }
}
