import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:chisto_mobile/features/home/data/map_regions/map_region_catalog.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';

/// Bounding regions for map area filtering (approximate administrative boxes, clamped to [ReportGeoFence]).
abstract final class MacedoniaMapRegions {
  MacedoniaMapRegions._();

  /// Metro / greater Skopje — parent for granular municipality filters.
  static const String skopjeMetroId = 'skopje';

  static const List<String> rootRegionIds = mapRootRegionIds;

  /// First entry repeats metro-wide [skopjeMetroId]; then urban municipalities.
  static const List<String> skopjeMunicipalityIds = mapSkopjeMunicipalityIds;

  static bool isSkopjeMetro(String? id) => id == skopjeMetroId;

  static bool isSkopjeMunicipalityId(String? id) =>
      id != null && id.startsWith('skopje_');

  static LatLngBounds? boundsFor(String? geoAreaId) {
    if (geoAreaId == null || geoAreaId.isEmpty) {
      return null;
    }
    return _bounds[geoAreaId];
  }

  static List<LatLng> fenceRingFor(String? geoAreaId) {
    final LatLngBounds? b = boundsFor(geoAreaId);
    if (b == null) {
      return const <LatLng>[];
    }
    return <LatLng>[
      b.southWest,
      b.southEast,
      b.northEast,
      b.northWest,
    ];
  }

  static final Map<String, LatLngBounds> _bounds = mapRegionBounds
      .map((String id, LatLngBounds b) => MapEntry<String, LatLngBounds>(id, _clampBounds(b)));

  static LatLngBounds _clampBounds(LatLngBounds raw) {
    return LatLngBounds(
      LatLng(
        raw.south.clamp(ReportGeoFence.minLat, ReportGeoFence.maxLat),
        raw.west.clamp(ReportGeoFence.minLng, ReportGeoFence.maxLng),
      ),
      LatLng(
        raw.north.clamp(ReportGeoFence.minLat, ReportGeoFence.maxLat),
        raw.east.clamp(ReportGeoFence.minLng, ReportGeoFence.maxLng),
      ),
    );
  }
}
