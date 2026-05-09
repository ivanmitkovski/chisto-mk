import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/cluster_bucket.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_marker_builder.dart';

/// Stable key for detecting when marker *geometry* (centers / partition) changes.
String mapMarkerGeometrySignature(List<ClusterBucket> clusters) {
  if (clusters.isEmpty) {
    return '';
  }
  final List<String> parts = <String>[];
  for (final ClusterBucket b in clusters) {
    parts.add(
      '${b.stableClusterId}@${b.center.latitude.toStringAsFixed(4)},${b.center.longitude.toStringAsFixed(4)}',
    );
  }
  parts.sort();
  return parts.join('\x1e');
}

Map<String, LatLng> _targetPointsByKey(List<ClusterBucket> clusters) {
  final Map<String, LatLng> out = <String, LatLng>{};
  for (final ClusterBucket b in clusters) {
    out[mapMarkerMotionKeyForBucket(b)] = b.center;
  }
  return out;
}

LatLng _latLngLerp(LatLng a, LatLng b, double t) {
  return LatLng(
    a.latitude + (b.latitude - a.latitude) * t,
    a.longitude + (b.longitude - a.longitude) * t,
  );
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
        final String clusterKey = 'c:${b.stableClusterId}';
        return visualNow[clusterKey] ?? b.center;
      }
    }
    return end;
  }
  if (key.startsWith('c:')) {
    ClusterBucket? nextBucket;
    for (final ClusterBucket b in next) {
      if (b.sites.length > 1 && 'c:${b.stableClusterId}' == key) {
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
      if (b.sites.length > 1 && 'c:${b.stableClusterId}' == key) {
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
    required this.cameraCenter,
    required this.onSiteTap,
    required this.onSiteLongPress,
    required this.onClusterTap,
    this.expansionOrigin,
    this.expandingSiteIds = const <String>{},
    this.expansionGhostCenter,
    this.expansionGhostColor,
    this.expansionGhostCount = 0,
    this.expansionToken = 0,
  });

  final List<ClusterBucket> clusters;
  final Map<String, LatLng> coords;
  final PollutionSite? selectedSite;
  final bool reduceAnimations;
  final LatLng cameraCenter;
  final void Function(PollutionSite site, LatLng center) onSiteTap;
  final void Function(PollutionSite site) onSiteLongPress;
  final void Function(ClusterBucket bucket) onClusterTap;
  final LatLng? expansionOrigin;
  final Set<String> expandingSiteIds;
  final LatLng? expansionGhostCenter;
  final Color? expansionGhostColor;
  final int expansionGhostCount;
  final int expansionToken;

  @override
  State<AnimatedPollutionMapMarkers> createState() =>
      _AnimatedPollutionMapMarkersState();
}

class _AnimatedPollutionMapMarkersState extends State<AnimatedPollutionMapMarkers>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.mapMarkerGeographicLerp,
  );

  /// Snapshot at animation start (logical keys → lat/lng).
  final Map<String, LatLng> _from = <String, LatLng>{};

  /// Target at animation end.
  final Map<String, LatLng> _to = <String, LatLng>{};

  String _lastGeometrySig = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    _controller.addStatusListener(_onStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_lastGeometrySig.isEmpty && widget.clusters.isNotEmpty) {
        setState(() {
          _to
            ..clear()
            ..addAll(_targetPointsByKey(widget.clusters));
          _lastGeometrySig = mapMarkerGeometrySignature(widget.clusters);
        });
      }
    });
  }

  void _onStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed) {
      setState(() {
        _from.clear();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Map<String, LatLng> _visualPositionsAtProgress(double rawT) {
    final double t = AppMotion.mapMarkerGeographicLerpCurve.transform(rawT);
    final Map<String, LatLng> out = <String, LatLng>{};
    for (final MapEntry<String, LatLng> e in _to.entries) {
      final LatLng? a = _from[e.key];
      out[e.key] = a == null ? e.value : _latLngLerp(a, e.value, t);
    }
    return out;
  }

  void _beginMotion(List<ClusterBucket> previous, List<ClusterBucket> next) {
    final Map<String, LatLng> newTargets = _targetPointsByKey(next);
    final Map<String, LatLng> visualNow = <String, LatLng>{};
    final double partialT = widget.reduceAnimations
        ? 1.0
        : (_controller.isAnimating ? _controller.value : 1.0);
    final double easedPartial =
        AppMotion.mapMarkerGeographicLerpCurve.transform(partialT);

    for (final MapEntry<String, LatLng> e in _to.entries) {
      final LatLng? a = _from[e.key];
      if (a != null) {
        visualNow[e.key] = _latLngLerp(a, e.value, easedPartial);
      } else {
        visualNow[e.key] = e.value;
      }
    }

    _from.clear();
    _to.clear();

    bool needsMotion = false;
    for (final MapEntry<String, LatLng> e in newTargets.entries) {
      final String k = e.key;
      final LatLng end = e.value;
      final LatLng start = visualNow[k] ??
          _warmStartForKey(
            key: k,
            end: end,
            previous: previous,
            next: next,
            visualNow: visualNow,
          );
      _from[k] = start;
      _to[k] = end;
      if ((start.latitude - end.latitude).abs() > 1e-9 ||
          (start.longitude - end.longitude).abs() > 1e-9) {
        needsMotion = true;
      }
    }

    if (widget.reduceAnimations || !needsMotion) {
      _controller.value = 1;
      _from.clear();
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant AnimatedPollutionMapMarkers oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceAnimations) {
      _controller.stop();
      _controller.value = 1;
      _from.clear();
      _to
        ..clear()
        ..addAll(_targetPointsByKey(widget.clusters));
      _lastGeometrySig = mapMarkerGeometrySignature(widget.clusters);
      return;
    }

    final String newSig = mapMarkerGeometrySignature(widget.clusters);
    if (newSig == _lastGeometrySig) {
      return;
    }
    _lastGeometrySig = newSig;

    if (oldWidget.clusters.isEmpty && widget.clusters.isNotEmpty) {
      _controller.value = 1;
      _from.clear();
      _to
        ..clear()
        ..addAll(_targetPointsByKey(widget.clusters));
      return;
    }

    _beginMotion(oldWidget.clusters, widget.clusters);
  }

  @override
  Widget build(BuildContext context) {
    final bool useLerp = !widget.reduceAnimations &&
        (_controller.isAnimating || _from.isNotEmpty);
    final Map<String, LatLng>? displayPoints = useLerp
        ? _visualPositionsAtProgress(_controller.value)
        : null;

    final List<Marker> markers = buildMapMarkers(
      clusters: widget.clusters,
      coords: widget.coords,
      selectedSite: widget.selectedSite,
      reduceAnimations: widget.reduceAnimations,
      cameraCenter: widget.cameraCenter,
      onSiteTap: widget.onSiteTap,
      onSiteLongPress: widget.onSiteLongPress,
      onClusterTap: widget.onClusterTap,
      expansionOrigin: widget.expansionOrigin,
      expandingSiteIds: widget.expandingSiteIds,
      expansionGhostCenter: widget.expansionGhostCenter,
      expansionGhostColor: widget.expansionGhostColor,
      expansionGhostCount: widget.expansionGhostCount,
      expansionToken: widget.expansionToken,
      markerDisplayPoints: displayPoints,
    );

    return MarkerLayer(markers: markers);
  }
}
