import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/utils/map_spiderfy.dart';
import 'package:feature_home/src/presentation/widgets/map/cluster_bucket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Immutable snapshot for cluster tap → burst pin / ghost / spiderfy choreography.
@immutable
class MapClusterExpansionState {
  const MapClusterExpansionState({
    this.expansionOrigin,
    this.expandingSiteIds = const <String>{},
    this.expansionToken = 0,
    this.ghostCenter,
    this.ghostColor,
    this.ghostCount = 0,
    this.spiderfyAnchor,
    this.spiderfyLegs = const <String, LatLng>{},
    this.isSpiderfied = false,
  });

  final LatLng? expansionOrigin;
  final Set<String> expandingSiteIds;
  final int expansionToken;
  final LatLng? ghostCenter;
  final Color? ghostColor;
  final int ghostCount;
  final LatLng? spiderfyAnchor;
  final Map<String, LatLng> spiderfyLegs;
  final bool isSpiderfied;

  static const MapClusterExpansionState initial = MapClusterExpansionState();

  MapClusterExpansionState clearedGhost() {
    return MapClusterExpansionState(
      expansionOrigin: expansionOrigin,
      expandingSiteIds: expandingSiteIds,
      expansionToken: expansionToken,
      spiderfyAnchor: spiderfyAnchor,
      spiderfyLegs: spiderfyLegs,
      isSpiderfied: isSpiderfied,
    );
  }

  MapClusterExpansionState clearedExpansion() {
    return MapClusterExpansionState(
      expansionToken: expansionToken,
      spiderfyAnchor: spiderfyAnchor,
      spiderfyLegs: spiderfyLegs,
      isSpiderfied: isSpiderfied,
    );
  }

  MapClusterExpansionState clearedSpiderfy() {
    return MapClusterExpansionState(expansionToken: expansionToken + 1);
  }
}

final mapClusterExpansionNotifierProvider =
    NotifierProvider<MapClusterExpansionNotifier, MapClusterExpansionState>(
      MapClusterExpansionNotifier.new,
    );

class MapClusterExpansionNotifier extends Notifier<MapClusterExpansionState> {
  Timer? _ghostClearTimer;
  Timer? _expansionClearTimer;

  @override
  MapClusterExpansionState build() {
    ref.onDispose(_cancelTimers);
    return MapClusterExpansionState.initial;
  }

  void _cancelTimers() {
    _ghostClearTimer?.cancel();
    _ghostClearTimer = null;
    _expansionClearTimer?.cancel();
    _expansionClearTimer = null;
  }

  void reset() {
    _cancelTimers();
    state = MapClusterExpansionState(expansionToken: state.expansionToken + 1);
  }

  void collapseSpiderfy() {
    if (!state.isSpiderfied) {
      return;
    }
    state = state.clearedSpiderfy();
  }

  void beginSpiderfy({
    required ClusterBucket bucket,
    required Map<String, LatLng> coordsById,
    required double zoom,
  }) {
    final List<LatLng> points = bucket.sites
        .map((PollutionSite s) => coordsById[s.id])
        .whereType<LatLng>()
        .toList();
    if (points.isEmpty) {
      return;
    }
    _cancelTimers();
    final Map<String, LatLng> memberCoords = <String, LatLng>{
      for (final PollutionSite s in bucket.sites)
        if (coordsById[s.id] != null) s.id: coordsById[s.id]!,
    };
    final Map<String, LatLng> legs = computeSpiderfyLegOffsets(
      anchor: bucket.center,
      memberCoords: memberCoords,
      zoom: zoom,
    );
    final Set<String> siteIds = bucket.sites
        .map((PollutionSite s) => s.id)
        .toSet();
    state = MapClusterExpansionState(
      expansionOrigin: bucket.center,
      expandingSiteIds: siteIds,
      expansionToken: state.expansionToken + 1,
      spiderfyAnchor: bucket.center,
      spiderfyLegs: legs,
      isSpiderfied: true,
    );
  }

  void beginExpansion({
    required ClusterBucket bucket,
    required Map<String, LatLng> coordsById,
  }) {
    final List<LatLng> points = bucket.sites
        .map((PollutionSite s) => coordsById[s.id])
        .whereType<LatLng>()
        .toList();
    if (points.isEmpty) {
      return;
    }

    _cancelTimers();

    final Set<String> siteIds = bucket.sites
        .map((PollutionSite s) => s.id)
        .toSet();
    final int nextToken = state.expansionToken + 1;
    state = MapClusterExpansionState(
      expansionOrigin: bucket.center,
      expandingSiteIds: siteIds,
      expansionToken: nextToken,
      ghostCenter: bucket.center,
      ghostColor: bucket.dominantColor,
      ghostCount: bucket.sites.length,
    );

    _ghostClearTimer = Timer(AppMotion.mapClusterGhostClear, () {
      _ghostClearTimer = null;
      state = state.clearedGhost();
    });
    _expansionClearTimer = Timer(AppMotion.mapClusterExpansionHold, () {
      _expansionClearTimer = null;
      state = state.clearedExpansion();
    });
  }
}
