import 'dart:async';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/providers/notifications_providers.dart';
import 'package:feature_home/src/data/map_realtime/map_realtime_service.dart';
import 'package:feature_home/src/data/map_realtime/map_site_event.dart';
import 'package:feature_home/src/data/map_realtime/map_sync_coordinator.dart';
import 'package:feature_home/src/data/map_realtime/map_sync_inline_notice.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/providers/repository_providers.dart';
import 'package:feature_notifications/feature_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  factory MapSitesState.fromSnapshot(MapSyncSnapshot s) {
    return MapSitesState(
      sites: s.sites,
      loadError: s.loadError,
      syncNotice: s.inlineNotice,
      lastSuccessfulSyncAt: s.lastSuccessfulSyncAt,
      cachedAt: s.cachedAt,
      isUsingPersistedFallback: s.isUsingPersistedFallback,
    );
  }

  final List<PollutionSite> sites;
  final AppError? loadError;
  final MapSyncInlineNotice? syncNotice;
  final DateTime? lastSuccessfulSyncAt;
  final DateTime? cachedAt;
  final bool isUsingPersistedFallback;
}

final mapSitesNotifierProvider =
    AutoDisposeNotifierProvider<MapSitesNotifier, MapSitesState>(
      MapSitesNotifier.new,
    );

class MapSitesNotifier extends AutoDisposeNotifier<MapSitesState> {
  static const Duration _connectionUnstableBannerGrace = Duration(seconds: 6);
  static const Duration _freshMapDataWindow = Duration(minutes: 5);

  late final MapSyncCoordinator _coordinator;
  StreamSubscription<MapSiteEvent>? _eventsSub;
  StreamSubscription<MapRealtimeConnectionState>? _sseStateSub;
  MapRealtimeConnectionState _sseState =
      MapRealtimeConnectionState.disconnected;
  Timer? _reconnectNoticeTimer;
  bool _showReconnectNotice = false;

  /// Override in widget tests to avoid waiting 6s for the debounce window.
  @visibleForTesting
  Duration connectionUnstableBannerGrace = _connectionUnstableBannerGrace;

  /// Override in widget tests for fresh-vs-stale banner gating.
  @visibleForTesting
  Duration freshMapDataWindow = _freshMapDataWindow;

  @override
  MapSitesState build() {
    _coordinator = MapSyncCoordinator(
      sitesRepository: ref.read(sitesRepositoryProvider),
    );
    _coordinator.addListener(_onCoordinatorChanged);
    _eventsSub = ref
        .read(mapRealtimeServiceProvider)
        .events
        .listen(_coordinator.ingestEvent);
    _sseStateSub = ref.read(mapRealtimeServiceProvider).states.listen((
      MapRealtimeConnectionState next,
    ) {
      if (_sseState == next) {
        return;
      }
      _sseState = next;
      _onSseStateChanged();
    });
    ref.onDispose(() {
      _reconnectNoticeTimer?.cancel();
      _reconnectNoticeTimer = null;
      _eventsSub?.cancel();
      _eventsSub = null;
      _sseStateSub?.cancel();
      _sseStateSub = null;
      _coordinator
        ..removeListener(_onCoordinatorChanged)
        ..dispose();
    });
    return _buildState();
  }

  void _onSseStateChanged() {
    if (_sseState == MapRealtimeConnectionState.reconnecting) {
      _reconnectNoticeTimer?.cancel();
      _reconnectNoticeTimer = Timer(connectionUnstableBannerGrace, () {
        _reconnectNoticeTimer = null;
        if (_sseState != MapRealtimeConnectionState.reconnecting) {
          return;
        }
        _showReconnectNotice = true;
        _onCoordinatorChanged();
      });
      _onCoordinatorChanged();
      return;
    }
    _reconnectNoticeTimer?.cancel();
    _reconnectNoticeTimer = null;
    if (_showReconnectNotice) {
      _showReconnectNotice = false;
    }
    if (_sseState == MapRealtimeConnectionState.live) {
      _maybeReconcileAfterSseLive();
    }
    _onCoordinatorChanged();
  }

  static const Duration _sseLiveReconcileStaleThreshold = Duration(seconds: 45);

  void _maybeReconcileAfterSseLive() {
    final DateTime? lastSync = _coordinator.snapshot.lastSuccessfulSyncAt;
    final bool stale =
        lastSync == null ||
        DateTime.now().difference(lastSync) > _sseLiveReconcileStaleThreshold;
    if (stale) {
      _coordinator.requestSync(immediate: false);
    }
  }

  MapSitesState _buildState() {
    final MapSitesState base = MapSitesState.fromSnapshot(
      _coordinator.snapshot,
    );
    if (_showReconnectNotice &&
        _sseState == MapRealtimeConnectionState.reconnecting &&
        base.syncNotice == null &&
        base.sites.isNotEmpty &&
        _mapDataIsStale(base)) {
      return MapSitesState(
        sites: base.sites,
        loadError: base.loadError,
        syncNotice: const MapSyncInlineNotice.connectionUnstable(),
        lastSuccessfulSyncAt: base.lastSuccessfulSyncAt,
        cachedAt: base.cachedAt,
        isUsingPersistedFallback: base.isUsingPersistedFallback,
      );
    }
    return base;
  }

  void _onCoordinatorChanged() {
    state = _buildState();
  }

  bool _mapDataIsStale(MapSitesState base) {
    final DateTime? lastSync = base.lastSuccessfulSyncAt;
    if (lastSync == null) {
      return true;
    }
    return DateTime.now().difference(lastSync) > freshMapDataWindow;
  }

  // ignore: avoid_positional_boolean_parameters, overridden by test fakes
  void setActive(bool active) {
    ref.read(mapRealtimeServiceProvider).setActive(active);
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

  @visibleForTesting
  void debugApplySseStateForTest(MapRealtimeConnectionState next) {
    if (_sseState == next) {
      return;
    }
    _sseState = next;
    _onSseStateChanged();
  }

  @visibleForTesting
  void debugSetLastSuccessfulSyncAtForTest(DateTime at) {
    _coordinator.debugSetLastSuccessfulSyncAt(at);
    _onCoordinatorChanged();
  }
}
