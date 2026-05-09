import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/cluster_bucket.dart';

/// Immutable snapshot for cluster tap → burst pin / ghost choreography.
@immutable
class MapClusterExpansionState {
  const MapClusterExpansionState({
    this.expansionOrigin,
    this.expandingSiteIds = const <String>{},
    this.expansionToken = 0,
    this.ghostCenter,
    this.ghostColor,
    this.ghostCount = 0,
  });

  final LatLng? expansionOrigin;
  final Set<String> expandingSiteIds;
  final int expansionToken;
  final LatLng? ghostCenter;
  final Color? ghostColor;
  final int ghostCount;

  static const MapClusterExpansionState initial = MapClusterExpansionState();

  /// Clears ghost fields; keeps expansion origin / burst IDs until expansion timer.
  MapClusterExpansionState clearedGhost() {
    return MapClusterExpansionState(
      expansionOrigin: expansionOrigin,
      expandingSiteIds: expandingSiteIds,
      expansionToken: expansionToken,
    );
  }

  /// Clears expansion choreography (pins stop bursting from cluster origin).
  MapClusterExpansionState clearedExpansion() {
    return MapClusterExpansionState(expansionToken: expansionToken);
  }
}

/// Owns timers and token bumps for cluster expansion animations (ghost + burst).
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

  /// Clears expansion + ghost immediately (filter change, tab inactive, dispose).
  void reset() {
    _cancelTimers();
    state = MapClusterExpansionState(
      expansionToken: state.expansionToken + 1,
    );
  }

  /// Begins burst choreography for [bucket]. No-op if no coordinates for members.
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

    final Set<String> siteIds =
        bucket.sites.map((PollutionSite s) => s.id).toSet();
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
