import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/home/data/map_regions/map_boundaries_repository.dart';

List<Polygon> buildRegionFence({
  required String? geoAreaId,
  required bool reduceMotion,
  required MapBoundariesRepository boundariesRepository,
}) {
  if (geoAreaId == null) {
    return const <Polygon>[];
  }
  final geometry = boundariesRepository.geometryFor(geoAreaId);
  if (geometry != null && geometry.polygons.isNotEmpty) {
    return geometry.polygons
        .map(
          (polygon) => Polygon(
            points: polygon.outerRing,
            holePointsList: polygon.holes,
            isFilled: true,
            color: AppColors.primary.withValues(alpha: reduceMotion ? 0.05 : 0.09),
            borderColor: AppColors.primary.withValues(alpha: 0.82),
            borderStrokeWidth: 2.0,
          ),
        )
        .toList(growable: false);
  }
  final List<LatLng> ring = boundariesRepository.fallbackRingFor(geoAreaId);
  if (ring.length < 3) {
    return const <Polygon>[];
  }
  return <Polygon>[
    Polygon(
      points: ring,
      isFilled: true,
      color: AppColors.primary.withValues(alpha: reduceMotion ? 0.05 : 0.09),
      borderColor: AppColors.primary.withValues(alpha: 0.82),
      borderStrokeWidth: 2.0,
    ),
  ];
}
