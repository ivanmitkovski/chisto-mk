import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:chisto_mobile/features/home/data/map_realtime/map_sync_coordinator.dart';

class MapViewportController {
  const MapViewportController();
  static const double _maxViewportSpanDegrees = 3.95;

  double radiusKmForZoom(double zoom) {
    if (zoom >= 14) return 8;
    if (zoom >= 12) return 18;
    if (zoom >= 10) return 40;
    if (zoom >= 8) return 90;
    return 150;
  }

  LatLngBounds prefetchQueryBoundsFromCamera(
    MapCamera camera,
    double overscanLogicalPx,
    LatLngBounds strictVisible,
  ) {
    final double w = camera.nonRotatedSize.x;
    final double h = camera.nonRotatedSize.y;
    if (w <= 0 || h <= 0) return strictVisible;
    final double o = overscanLogicalPx.clamp(40.0, 120.0);
    final List<LatLng> corners = <LatLng>[
      camera.pointToLatLng(math.Point<double>(-o, -o)),
      camera.pointToLatLng(math.Point<double>(w + o, -o)),
      camera.pointToLatLng(math.Point<double>(w + o, h + o)),
      camera.pointToLatLng(math.Point<double>(-o, h + o)),
    ];
    double south = strictVisible.south;
    double north = strictVisible.north;
    double west = strictVisible.west;
    double east = strictVisible.east;
    for (final LatLng p in corners) {
      south = math.min(south, p.latitude);
      north = math.max(north, p.latitude);
      west = math.min(west, p.longitude);
      east = math.max(east, p.longitude);
    }
    return LatLngBounds(LatLng(south, west), LatLng(north, east));
  }

  MapViewportQuery buildViewportQuery({
    required double latitude,
    required double longitude,
    required double zoom,
    required LatLngBounds? visibleBounds,
    required int limit,
    bool includeArchived = false,
  }) {
    final LatLngBounds? boundedVisible = _clampViewportSpan(visibleBounds);
    return MapViewportQuery(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKmForZoom(zoom),
      limit: limit,
      zoom: zoom,
      includeArchived: includeArchived,
      minLatitude: boundedVisible?.south,
      maxLatitude: boundedVisible?.north,
      minLongitude: boundedVisible?.west,
      maxLongitude: boundedVisible?.east,
    );
  }

  LatLngBounds? _clampViewportSpan(LatLngBounds? bounds) {
    if (bounds == null) {
      return null;
    }
    final double latSpan = (bounds.north - bounds.south).abs();
    final double lngSpan = (bounds.east - bounds.west).abs();
    if (latSpan <= _maxViewportSpanDegrees && lngSpan <= _maxViewportSpanDegrees) {
      return bounds;
    }

    final double centerLat = (bounds.north + bounds.south) / 2;
    final double centerLng = (bounds.east + bounds.west) / 2;
    final double halfLat = math.min(latSpan, _maxViewportSpanDegrees) / 2;
    final double halfLng = math.min(lngSpan, _maxViewportSpanDegrees) / 2;

    return LatLngBounds(
      LatLng(centerLat - halfLat, centerLng - halfLng),
      LatLng(centerLat + halfLat, centerLng + halfLng),
    );
  }
}
