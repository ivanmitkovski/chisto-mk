import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';

import 'package:chisto_mobile/features/home/data/map_regions/macedonia_map_regions.dart';
import 'package:chisto_mobile/features/home/data/map_regions/map_region_geometry.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';

class MapBoundariesRepository {
  MapBoundariesRepository._();

  static const String _assetPath =
      'assets/map_boundaries/municipalities_filter_scope.geojson';
  static const double _simplifyToleranceDegrees = 0.00022;
  static const int _maxRingPoints = 360;

  static final MapBoundariesRepository instance = MapBoundariesRepository._();

  Future<void>? _loadFuture;
  final Map<String, MapRegionGeometry> _byId = <String, MapRegionGeometry>{};
  final Set<String> _unmappedShapeNames = <String>{};

  bool get isLoaded => _byId.isNotEmpty;
  Set<String> get unmappedShapeNames => Set<String>.from(_unmappedShapeNames);

  Future<void> warmup() {
    _loadFuture ??= _load();
    return _loadFuture!;
  }

  MapRegionGeometry? geometryFor(String? mapId) {
    final String? canonical = _canonicalMapId(mapId);
    if (canonical == null) {
      return null;
    }
    return _byId[canonical];
  }

  LatLngBounds? boundsFor(String? mapId) {
    return geometryFor(mapId)?.bounds;
  }

  List<LatLng> fallbackRingFor(String? mapId) {
    return MacedoniaMapRegions.fenceRingFor(mapId);
  }

  Future<void> _load() async {
    try {
      final String raw = await rootBundle.loadString(_assetPath);
      final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
      final List<dynamic> features = json['features'] as List<dynamic>? ?? const <dynamic>[];
      final Map<String, MapRegionGeometry> next = <String, MapRegionGeometry>{};
      _unmappedShapeNames.clear();

      for (final dynamic entry in features) {
        final Map<String, dynamic>? feature = entry as Map<String, dynamic>?;
        if (feature == null) {
          continue;
        }
        final Map<String, dynamic>? props =
            feature['properties'] as Map<String, dynamic>?;
        final String? mapId = _extractMapId(props);
        if (mapId == null || mapId.isEmpty) {
          continue;
        }
        final Map<String, dynamic>? geometry =
            feature['geometry'] as Map<String, dynamic>?;
        final List<MapRegionPolygonGeometry> polygons = _parseGeometry(geometry);
        if (polygons.isEmpty) {
          continue;
        }
        next[mapId] = MapRegionGeometry(id: mapId, polygons: polygons);
      }

      _byId
        ..clear()
        ..addAll(next);
    } catch (_) {
      _byId.clear();
    }
  }

  String? _extractMapId(Map<String, dynamic>? props) {
    final String? rawId = props?['mapId'] as String?;
    final String? canonicalRaw = _canonicalMapId(rawId);
    if (canonicalRaw != null) {
      return canonicalRaw;
    }
    final String? shapeName = props?['mapName'] as String? ?? props?['shapeName'] as String?;
    if (shapeName == null || shapeName.isEmpty) {
      return null;
    }
    final String slug = shapeName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final String? canonicalShape = _canonicalMapId(slug);
    if (canonicalShape != null) {
      return canonicalShape;
    }
    _unmappedShapeNames.add(shapeName);
    return null;
  }

  List<MapRegionPolygonGeometry> _parseGeometry(Map<String, dynamic>? geometry) {
    if (geometry == null) {
      return const <MapRegionPolygonGeometry>[];
    }
    final String? type = geometry['type'] as String?;
    final dynamic coordinates = geometry['coordinates'];
    if (type == 'Polygon') {
      final MapRegionPolygonGeometry? polygon = _parsePolygonCoordinates(coordinates);
      return polygon == null
          ? const <MapRegionPolygonGeometry>[]
          : <MapRegionPolygonGeometry>[polygon];
    }
    if (type == 'MultiPolygon') {
      final List<dynamic>? all = coordinates as List<dynamic>?;
      if (all == null) {
        return const <MapRegionPolygonGeometry>[];
      }
      return all
          .map<MapRegionPolygonGeometry?>(
            (dynamic c) => _parsePolygonCoordinates(c),
          )
          .whereType<MapRegionPolygonGeometry>()
          .toList(growable: false);
    }
    return const <MapRegionPolygonGeometry>[];
  }

  MapRegionPolygonGeometry? _parsePolygonCoordinates(dynamic coordinates) {
    final List<dynamic>? ringsRaw = coordinates as List<dynamic>?;
    if (ringsRaw == null || ringsRaw.isEmpty) {
      return null;
    }
    final List<LatLng> outer = _parseRing(ringsRaw.first);
    if (outer.length < 3) {
      return null;
    }
    final List<List<LatLng>> holes = ringsRaw
        .skip(1)
        .map<List<LatLng>>(_parseRing)
        .where((List<LatLng> ring) => ring.length >= 3)
        .toList(growable: false);

    return MapRegionPolygonGeometry(outerRing: outer, holes: holes);
  }

  List<LatLng> _parseRing(dynamic ringRaw) {
    final List<dynamic>? pointsRaw = ringRaw as List<dynamic>?;
    if (pointsRaw == null || pointsRaw.length < 3) {
      return const <LatLng>[];
    }

    final List<LatLng> points = <LatLng>[];
    for (final dynamic pointRaw in pointsRaw) {
      final List<dynamic>? coords = pointRaw as List<dynamic>?;
      if (coords == null || coords.length < 2) {
        continue;
      }
      final double? lng = (coords[0] as num?)?.toDouble();
      final double? lat = (coords[1] as num?)?.toDouble();
      if (lat == null || lng == null) {
        continue;
      }
      if (!_isInsideFence(lat, lng)) {
        continue;
      }
      points.add(LatLng(lat, lng));
    }
    final List<LatLng> normalized = _normalizeRing(points);
    if (normalized.length < 4) {
      return const <LatLng>[];
    }
    return _simplifyRing(normalized);
  }

  List<LatLng> _normalizeRing(List<LatLng> points) {
    if (points.length < 3) {
      return const <LatLng>[];
    }
    final List<LatLng> deduped = <LatLng>[];
    for (final LatLng p in points) {
      if (deduped.isEmpty) {
        deduped.add(p);
        continue;
      }
      final LatLng prev = deduped.last;
      final bool same = prev.latitude == p.latitude && prev.longitude == p.longitude;
      if (!same) {
        deduped.add(p);
      }
    }
    if (deduped.length < 3) {
      return const <LatLng>[];
    }
    final LatLng first = deduped.first;
    final LatLng last = deduped.last;
    if (first.latitude != last.latitude || first.longitude != last.longitude) {
      deduped.add(first);
    }
    final Set<String> unique = deduped
        .map((LatLng p) => '${p.latitude.toStringAsFixed(8)},${p.longitude.toStringAsFixed(8)}')
        .toSet();
    if (unique.length < 3) {
      return const <LatLng>[];
    }
    return deduped;
  }

  List<LatLng> _simplifyRing(List<LatLng> points) {
    if (points.length <= 5) {
      return points;
    }

    final bool closed = points.first.latitude == points.last.latitude &&
        points.first.longitude == points.last.longitude;
    final List<LatLng> open = closed ? points.sublist(0, points.length - 1) : points;
    if (open.length <= 3) {
      return points;
    }

    final List<LatLng> simplified = _douglasPeucker(open, _simplifyToleranceDegrees);
    List<LatLng> closedRing = <LatLng>[...simplified, simplified.first];
    if (closedRing.length > _maxRingPoints) {
      final int step = math.max(1, (closedRing.length / _maxRingPoints).ceil());
      final List<LatLng> capped = <LatLng>[];
      for (int i = 0; i < closedRing.length; i += step) {
        capped.add(closedRing[i]);
      }
      if (capped.first.latitude != capped.last.latitude ||
          capped.first.longitude != capped.last.longitude) {
        capped.add(capped.first);
      }
      closedRing = capped;
    }
    if (closedRing.length < 4) {
      return points;
    }
    return closedRing;
  }

  List<LatLng> _douglasPeucker(List<LatLng> points, double epsilon) {
    if (points.length < 3) {
      return points;
    }
    final int index = _farthestPointIndex(points);
    final double distance = _perpendicularDistance(
      points[index],
      points.first,
      points.last,
    );
    if (distance <= epsilon) {
      return <LatLng>[points.first, points.last];
    }
    final List<LatLng> left = _douglasPeucker(points.sublist(0, index + 1), epsilon);
    final List<LatLng> right = _douglasPeucker(points.sublist(index), epsilon);
    return <LatLng>[...left.sublist(0, left.length - 1), ...right];
  }

  int _farthestPointIndex(List<LatLng> points) {
    int index = 1;
    double maxDistance = -1;
    for (int i = 1; i < points.length - 1; i++) {
      final double distance = _perpendicularDistance(
        points[i],
        points.first,
        points.last,
      );
      if (distance > maxDistance) {
        maxDistance = distance;
        index = i;
      }
    }
    return index;
  }

  double _perpendicularDistance(LatLng point, LatLng start, LatLng end) {
    final double dx = end.longitude - start.longitude;
    final double dy = end.latitude - start.latitude;
    if (dx == 0 && dy == 0) {
      return math.sqrt(
        math.pow(point.longitude - start.longitude, 2) +
            math.pow(point.latitude - start.latitude, 2),
      );
    }
    final double num = (dy * point.longitude) -
        (dx * point.latitude) +
        (end.longitude * start.latitude) -
        (end.latitude * start.longitude);
    final double den = math.sqrt(dx * dx + dy * dy);
    return num.abs() / den;
  }

  bool _isInsideFence(double lat, double lng) {
    return lat >= ReportGeoFence.minLat &&
        lat <= ReportGeoFence.maxLat &&
        lng >= ReportGeoFence.minLng &&
        lng <= ReportGeoFence.maxLng;
  }

  String? _canonicalMapId(String? id) {
    if (id == null || id.isEmpty) {
      return null;
    }
    return _mapIdAliases[id] ?? id;
  }

  static const Map<String, String> _mapIdAliases = <String, String>{
    'shtip': 'stip',
    'stip': 'stip',
    'strumitsa': 'strumica',
    'kavadartsi': 'kavadarci',
    'kochani': 'kocani',
    'radovish': 'radovis',
    'vinitsa': 'vinica',
    'delchevo': 'delcevo',
    'probishtip': 'probistip',
    'kichevo': 'kicevo',
    'gjorche_petrov': 'skopje_gjorce_petrov',
    'centar': 'skopje_centar',
    'aerodrom': 'skopje_aerodrom',
    'karposh': 'skopje_karposh',
    'chair': 'skopje_chair',
    'kisela_voda': 'skopje_kisela_voda',
    'gazi_baba': 'skopje_gazi_baba',
    'butel': 'skopje_butel',
    'saraj': 'skopje_saraj',
    'shuto_orizari': 'skopje_shuto_orizari',
  };
}

