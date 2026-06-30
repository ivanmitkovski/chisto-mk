import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Computes spiderfy leg positions for co-located or non-separable clusters.
///
/// Returns siteId → offset from [anchor] in degrees (deterministic, sorted ids).
Map<String, LatLng> computeSpiderfyLegOffsets({
  required LatLng anchor,
  required Map<String, LatLng> memberCoords,
  required double zoom,
  double markerDiameterPx = 68,
}) {
  if (memberCoords.length <= 1) {
    return memberCoords;
  }

  final List<String> ids = memberCoords.keys.toList()..sort();
  final double threshold =
      markerDiameterPx * 360 / (math.pow(2, zoom.clamp(1, 20)) * 256);
  final double legRadius = threshold * 1.35;

  final Map<String, LatLng> legs = <String, LatLng>{};
  final int n = ids.length;
  for (int i = 0; i < n; i++) {
    final String id = ids[i];
    final LatLng base = memberCoords[id] ?? anchor;
    if (n == 1) {
      legs[id] = base;
      continue;
    }
    final double angle = (2 * math.pi * i / n) - math.pi / 2;
    final double dLat = legRadius * math.sin(angle);
    final double dLng =
        legRadius *
        math.cos(angle) /
        math.cos(anchor.latitude * math.pi / 180).clamp(0.2, 1.0);
    legs[id] = LatLng(anchor.latitude + dLat, anchor.longitude + dLng);
  }
  return legs;
}

/// True when bounds-fit at [maxZoom] would not visually separate members.
bool clusterNeedsSpiderfy({
  required Iterable<LatLng> points,
  required double zoom,
  double minSeparationPx = 56,
}) {
  if (points.length <= 1) {
    return false;
  }
  final List<LatLng> list = points.toList();
  final double minSpan =
      minSeparationPx * 360 / (math.pow(2, zoom.clamp(1, 20)) * 256);
  double maxDist = 0;
  for (int i = 0; i < list.length; i++) {
    for (int j = i + 1; j < list.length; j++) {
      final double dLat = list[i].latitude - list[j].latitude;
      final double dLng = list[i].longitude - list[j].longitude;
      final double d = math.sqrt(dLat * dLat + dLng * dLng);
      if (d > maxDist) {
        maxDist = d;
      }
    }
  }
  return maxDist < minSpan * 1.2;
}

/// Screen-space span in degrees at zoom (approx).
double clusterSpanDegrees(Iterable<LatLng> points) {
  if (points.isEmpty) {
    return 0;
  }
  double minLat = double.infinity;
  double maxLat = -double.infinity;
  double minLng = double.infinity;
  double maxLng = -double.infinity;
  for (final LatLng p in points) {
    minLat = math.min(minLat, p.latitude);
    maxLat = math.max(maxLat, p.latitude);
    minLng = math.min(minLng, p.longitude);
    maxLng = math.max(maxLng, p.longitude);
  }
  final double spanLat = (maxLat - minLat).abs();
  final double spanLng = (maxLng - minLng).abs();
  return math.sqrt(spanLat * spanLat + spanLng * spanLng);
}

/// Leader lines drawn under spiderfied pins.
List<Polyline> buildSpiderfyPolylines({
  required LatLng? anchor,
  required Map<String, LatLng> legs,
  required bool reduceMotion,
}) {
  if (anchor == null || legs.isEmpty || reduceMotion) {
    return const <Polyline>[];
  }
  final Color lineColor = AppColors.textSecondary.withValues(alpha: 0.42);
  return legs.values
      .map(
        (LatLng leg) => Polyline(
          points: <LatLng>[anchor, leg],
          color: lineColor,
          strokeWidth: 1.5,
        ),
      )
      .toList(growable: false);
}
