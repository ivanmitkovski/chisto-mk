import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/home/data/map_realtime/map_site_event.dart';
import 'package:chisto_mobile/features/home/data/map_realtime/map_sync_coordinator.dart';
import 'package:chisto_mobile/features/home/data/map_realtime/map_sync_inline_notice.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/providers/repository_providers.dart';

/// Snapshot of map site list + sync metadata for UI.
class MapSitesState {
  const MapSitesState({
    this.sites = const <PollutionSite>[],
    this.loadError,
    this.syncNotice,
    this.lastSuccessfulSyncAt,
    this.cachedAt,
    this.isUsingPersistedFallback = false,
  });

  final List<PollutionSite> sites;
  final AppError? loadError;
  final MapSyncInlineNotice? syncNotice;
  final DateTime? lastSuccessfulSyncAt;
  final DateTime? cachedAt;
  final bool isUsingPersistedFallback;

  static MapSitesState fromSnapshot(MapSyncSnapshot s) {
    return MapSitesState(
      sites: s.sites,
      loadError: s.loadError,
      syncNotice: s.inlineNotice,
      lastSuccessfulSyncAt: s.lastSuccessfulSyncAt,
      cachedAt: s.cachedAt,
      isUsingPersistedFallback: s.isUsingPersistedFallback,
    );
  }
}

final mapSitesNotifierProvider =
    AutoDisposeNotifierProvider<MapSitesNotifier, MapSitesState>(
      MapSitesNotifier.new,
    );

class MapSitesNotifier extends AutoDisposeNotifier<MapSitesState> {
  late final MapSyncCoordinator _coordinator;
  StreamSubscription<MapSiteEvent>? _eventsSub;

  @override
  MapSitesState build() {
    _coordinator = MapSyncCoordinator(
      sitesRepository: ref.read(sitesRepositoryProvider),
      offlineRegionStore: ServiceLocator.instance.offlineRegionStore,
    );
    _coordinator.addListener(_onCoordinatorChanged);
    _eventsSub = ServiceLocator.instance.mapRealtimeService.events.listen(
      _coordinator.ingestEvent,
    );
    ref.onDispose(() {
      _eventsSub?.cancel();
      _eventsSub = null;
      _coordinator
        ..removeListener(_onCoordinatorChanged)
        ..dispose();
    });
    return MapSitesState.fromSnapshot(_coordinator.snapshot);
  }

  void _onCoordinatorChanged() {
    final MapSitesState next = MapSitesState.fromSnapshot(
      _coordinator.snapshot,
    );
    state = next;
  }

  void setActive(bool active) {
    ServiceLocator.instance.mapRealtimeService.setActive(active);
    _coordinator.setActive(active);
  }

  void updateViewport(MapViewportQuery query) {
    _coordinator.updateViewport(query);
  }

  void requestSync({required bool immediate}) {
    _coordinator.requestSync(immediate: immediate);
  }

  void recordPanGestureEnd({
    required double centerLat,
    required double centerLng,
    required double zoom,
  }) {
    _coordinator.schedulePredictivePrefetchFromPan(
      centerLat: centerLat,
      centerLng: centerLng,
      zoom: zoom,
    );
  }

  void upsertSiteFromFocus(PollutionSite site) {
    _coordinator.upsertSite(site);
  }
}
