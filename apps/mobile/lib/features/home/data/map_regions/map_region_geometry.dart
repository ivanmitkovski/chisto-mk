import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapRegionPolygonGeometry {
  const MapRegionPolygonGeometry({
    required this.outerRing,
    this.holes = const <List<LatLng>>[],
  });

  final List<LatLng> outerRing;
  final List<List<LatLng>> holes;
}

class MapRegionGeometry {
  const MapRegionGeometry({
    required this.id,
    required this.polygons,
  });

  final String id;
  final List<MapRegionPolygonGeometry> polygons;

  LatLngBounds get bounds {
    double minLat = double.infinity;
    double minLng = double.infinity;
    double maxLat = -double.infinity;
    double maxLng = -double.infinity;

    for (final MapRegionPolygonGeometry polygon in polygons) {
      for (final LatLng point in polygon.outerRing) {
        minLat = math.min(minLat, point.latitude);
        minLng = math.min(minLng, point.longitude);
        maxLat = math.max(maxLat, point.latitude);
        maxLng = math.max(maxLng, point.longitude);
      }
    }

    if (!minLat.isFinite || !minLng.isFinite || !maxLat.isFinite || !maxLng.isFinite) {
      return LatLngBounds(const LatLng(0, 0), const LatLng(0, 0));
    }
    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }
}

