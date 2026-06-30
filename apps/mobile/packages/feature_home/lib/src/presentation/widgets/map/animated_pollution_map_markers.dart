import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/widgets/map/cluster_bucket.dart';
import 'package:feature_home/src/presentation/widgets/map/map_marker_builder.dart';
import 'package:feature_home/src/presentation/widgets/map/map_marker_entrance_cache.dart';
import 'package:feature_home/src/presentation/widgets/map/map_marker_spring_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Stable key for detecting when marker *geometry* (centers / partition) changes.
String mapMarkerGeometrySignature(List<ClusterBucket> clusters) {
  if (clusters.isEmpty) {
    return '';
  }
  final List<String> parts = <String>[];
  for (final ClusterBucket b in clusters) {
    parts.add(
      '${b.anchorId}@${b.center.latitude.toStringAsFixed(4)},${b.center.longitude.toStringAsFixed(4)}',
    );
  }
  parts.sort();
  return parts.join('\x1e');
}

Map<String, LatLng> _targetPointsByKey(
  List<ClusterBucket> clusters, {
  Map<String, LatLng>? spiderfyLegs,
}) {
  final Map<String, LatLng> out = <String, LatLng>{};
  for (final ClusterBucket b in clusters) {
    if (b.sites.length == 1) {
      final String siteId = b.sites.first.id;
      out[mapMarkerMotionKeyForBucket(b)] = spiderfyLegs?[siteId] ?? b.center;
      continue;
    }
    out[mapMarkerMotionKeyForBucket(b)] = b.center;
  }
  return out;
}

LatLng _warmStartForKey({
  required String key,
  required LatLng end,
  required List<ClusterBucket> previous,
  required List<ClusterBucket> next,
  required Map<String, LatLng> visualNow,
}) {
  if (key.startsWith('s:')) {
    final String siteId = key.substring(2);
    for (final ClusterBucket b in previous) {
      if (b.sites.length <= 1) {
        continue;
      }
      if (b.sites.any((PollutionSite s) => s.id == siteId)) {
        final String clusterKey = 'c:${b.anchorId}';
        return visualNow[clusterKey] ?? b.center;
      }
    }
    return end;
  }
  if (key.startsWith('c:')) {
    ClusterBucket? nextBucket;
    for (final ClusterBucket b in next) {
      if (b.sites.length > 1 && 'c:${b.anchorId}' == key) {
        nextBucket = b;
        break;
      }
    }
    if (nextBucket != null) {
      double lat = 0;
      double lng = 0;
      int n = 0;
      for (final PollutionSite s in nextBucket.sites) {
        final LatLng? p = visualNow['s:${s.id}'];
        if (p != null) {
          lat += p.latitude;
          lng += p.longitude;
          n++;
        }
      }
      if (n > 0) {
        return LatLng(lat / n, lng / n);
      }
    }
    ClusterBucket? prevBucket;
    for (final ClusterBucket b in previous) {
      if (b.sites.length > 1 && 'c:${b.anchorId}' == key) {
        prevBucket = b;
        break;
      }
    }
    if (prevBucket == null) {
      return end;
    }
    double lat = 0;
    double lng = 0;
    int n = 0;
    for (final PollutionSite s in prevBucket.sites) {
      final LatLng? p = visualNow['s:${s.id}'];
      if (p != null) {
        lat += p.latitude;
        lng += p.longitude;
        n++;
      }
    }
    if (n == 0) {
      return end;
    }
    return LatLng(lat / n, lng / n);
  }
  return end;
}

/// Wraps [MarkerLayer] and eases each marker’s geographic point when clusters reflow.
class AnimatedPollutionMapMarkers extends StatefulWidget {
  const AnimatedPollutionMapMarkers({
    super.key,
    required this.clusters,
    required this.coords,
    required this.selectedSite,
    required this.reduceAnimations,
    this.skipEntranceAnimations = false,
    required this.cameraCenter,
    required this.onSiteTap,
    required this.onSiteLongPress,
    required this.onClusterTap,
    required this.entranceCache,
    this.expansionOrigin,
    this.expandingSiteIds = const <String>{},
    this.expansionGhostCenter,
    this.expansionGhostColor,
    this.expansionGhostCount = 0,
    this.expansionToken = 0,
    this.spiderfyLegs = const <String, LatLng>{},
    this.spiderfyAnchor,
    this.spiderfyLines = const <SpiderfyLine>{},
  });

  final List<ClusterBucket> clusters;
  final Map<String, LatLng> coords;
  final PollutionSite? selectedSite;
  final bool reduceAnimations;
  final bool skipEntranceAnimations;
  final LatLng cameraCenter;
  final void Function(PollutionSite site, LatLng center) onSiteTap;
  final void Function(PollutionSite site) onSiteLongPress;
  final void Function(ClusterBucket bucket) onClusterTap;
  final MapMarkerEntranceCache entranceCache;
  final LatLng? expansionOrigin;
  final Set<String> expandingSiteIds;
  final LatLng? expansionGhostCenter;
  final Color? expansionGhostColor;
  final int expansionGhostCount;
  final int expansionToken;
  final Map<String, LatLng> spiderfyLegs;
  final LatLng? spiderfyAnchor;
  final Set<SpiderfyLine> spiderfyLines;

  @override
  State<AnimatedPollutionMapMarkers> createState() =>
      _AnimatedPollutionMapMarkersState();
}

class _AnimatedPollutionMapMarkersState
    extends State<AnimatedPollutionMapMarkers>
    with SingleTickerProviderStateMixin {
  final Map<String, MapMarkerSpringPair> _springs =
      <String, MapMarkerSpringPair>{};
  final Map<String, LatLng> _restPositions = <String, LatLng>{};

  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  String _lastGeometrySig = '';
  bool _needsTick = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_lastGeometrySig.isEmpty && widget.clusters.isNotEmpty) {
        _syncRestTargets(widget.clusters);
        _lastGeometrySig = mapMarkerGeometrySignature(widget.clusters);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) {
      return;
    }
    final double dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    var allSettled = true;
    for (final MapMarkerSpringPair pair in _springs.values) {
      pair.elapsed += dt;
      if (!pair.isSettled(pair.elapsed)) {
        allSettled = false;
      }
    }
    setState(() {});
    if (allSettled) {
      _needsTick = false;
      _ticker?.stop();
    }
  }

  void _ensureTicking() {
    if (_needsTick) {
      return;
    }
    _needsTick = true;
    _lastTick = Duration.zero;
    _ticker?.start();
  }

  Map<String, LatLng> _visualNow() {
    final Map<String, LatLng> out = <String, LatLng>{};
    for (final MapEntry<String, LatLng> e in _restPositions.entries) {
      final MapMarkerSpringPair? spring = _springs[e.key];
      out[e.key] = spring?.positionAt(spring.elapsed) ?? e.value;
    }
    return out;
  }

  void _syncRestTargets(List<ClusterBucket> clusters) {
    final Map<String, LatLng> targets = _targetPointsByKey(
      clusters,
      spiderfyLegs: widget.spiderfyLegs,
    );
    _restPositions
      ..clear()
      ..addAll(targets);
  }

  void _beginMotion(List<ClusterBucket> previous, List<ClusterBucket> next) {
    final Map<String, LatLng> newTargets = _targetPointsByKey(
      next,
      spiderfyLegs: widget.spiderfyLegs,
    );
    final Map<String, LatLng> visualNow = _visualNow();
    final SpringDescription spring = AppMotion.mapMarkerSettleSpring;

    final Set<String> keys = newTargets.keys.toSet();
    for (final String k in _springs.keys.toList()) {
      if (!keys.contains(k)) {
        _springs.remove(k);
      }
    }

    var needsMotion = false;
    for (final MapEntry<String, LatLng> e in newTargets.entries) {
      final String k = e.key;
      final LatLng end = e.value;
      final LatLng start =
          visualNow[k] ??
          _warmStartForKey(
            key: k,
            end: end,
            previous: previous,
            next: next,
            visualNow: visualNow,
          );

      _restPositions[k] = end;

      final MapMarkerSpringPair? existing = _springs[k];
      if (existing != null &&
          (start.latitude - end.latitude).abs() < 1e-9 &&
          (start.longitude - end.longitude).abs() < 1e-9) {
        _springs.remove(k);
        continue;
      }

      if ((start.latitude - end.latitude).abs() > 1e-9 ||
          (start.longitude - end.longitude).abs() > 1e-9) {
        needsMotion = true;
      }

      if (existing == null) {
        _springs[k] = MapMarkerSpringPair(
          start: start,
          end: end,
          spring: spring,
        );
      } else {
        existing.retarget(from: start, to: end, spring: spring);
      }
    }

    if (!needsMotion) {
      _springs.clear();
      _ticker?.stop();
      _needsTick = false;
      return;
    }
    _ensureTicking();
  }

  @override
  void didUpdateWidget(covariant AnimatedPollutionMapMarkers oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceAnimations) {
      _springs.clear();
      _ticker?.stop();
      _needsTick = false;
      _syncRestTargets(widget.clusters);
      _lastGeometrySig = mapMarkerGeometrySignature(widget.clusters);
      setState(() {});
      return;
    }

    final String newSig = mapMarkerGeometrySignature(widget.clusters);
    if (newSig == _lastGeometrySig &&
        widget.spiderfyLegs == oldWidget.spiderfyLegs) {
      return;
    }
    _lastGeometrySig = newSig;

    if (oldWidget.clusters.isEmpty && widget.clusters.isNotEmpty) {
      _springs.clear();
      _syncRestTargets(widget.clusters);
      return;
    }

    _beginMotion(oldWidget.clusters, widget.clusters);
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, LatLng>? displayPoints =
        widget.reduceAnimations || _springs.isEmpty ? null : _visualNow();

    final List<Marker> markers = buildMapMarkers(
      clusters: widget.clusters,
      coords: widget.coords,
      selectedSite: widget.selectedSite,
      reduceAnimations: widget.reduceAnimations,
      skipEntranceAnimations: widget.skipEntranceAnimations,
      cameraCenter: widget.cameraCenter,
      onSiteTap: widget.onSiteTap,
      onSiteLongPress: widget.onSiteLongPress,
      onClusterTap: widget.onClusterTap,
      entranceCache: widget.entranceCache,
      expansionOrigin: widget.expansionOrigin,
      expandingSiteIds: widget.expandingSiteIds,
      expansionGhostCenter: widget.expansionGhostCenter,
      expansionGhostColor: widget.expansionGhostColor,
      expansionGhostCount: widget.expansionGhostCount,
      expansionToken: widget.expansionToken,
      markerDisplayPoints: displayPoints,
      spiderfyLegs: widget.spiderfyLegs,
      spiderfyLines: widget.spiderfyLines,
    );

    return MarkerLayer(markers: markers);
  }
}

/// Leader line from cluster anchor to spiderfied pin (map coordinates).
@immutable
class SpiderfyLine {
  const SpiderfyLine({required this.from, required this.to});

  final LatLng from;
  final LatLng to;

  @override
  bool operator ==(Object other) =>
      other is SpiderfyLine &&
      from.latitude == other.from.latitude &&
      from.longitude == other.from.longitude &&
      to.latitude == other.to.latitude &&
      to.longitude == other.to.longitude;

  @override
  int get hashCode =>
      Object.hash(from.latitude, from.longitude, to.latitude, to.longitude);
}
