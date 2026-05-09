import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/cluster_bucket.dart';

/// Pixel-radius threshold → degrees (same formula as legacy map screen).
double mapClusterThresholdDegrees(double zoom) {
  const double pixelRadius = 50;
  return pixelRadius * 360 / (math.pow(2, zoom.clamp(1, 20)) * 256);
}

/// Buckets fractional zoom used only for clustering so minor smooth-zoom steps map
/// to stable thresholds between recomputations (avoids isolate spam + jitter).
double quantizeZoomForClusterRecompute(double zoom) {
  const int stepsPerUnit = 112;
  return (zoom.clamp(1.0, 20.0) * stepsPerUnit).round() / stepsPerUnit;
}

int mapEntranceDelayMsForPoint(
  LatLng point, {
  required double cameraCenterLat,
  required double cameraCenterLng,
}) {
  final double dLat = (point.latitude - cameraCenterLat).abs();
  final double dLng = (point.longitude - cameraCenterLng).abs();
  final double distance = math.sqrt(dLat * dLat + dLng * dLng);
  const double maxDistance = 0.035;
  final int delayMs = (distance / maxDistance * 320).round().clamp(0, 380);
  return delayMs;
}

/// True when two points should cluster at [threshold] (degrees from
/// [mapClusterThresholdDegrees]).
///
/// Uses squared Euclidean distance in degree space: **L2² ≤ 2·threshold²**.
/// That disk circumscribes the legacy axis-aligned box **|Δlat|, |Δlng| ≤ threshold**,
/// so every old merge still merges, plus a thin diagonal band of additional merges
/// (rotation-invariant, deterministic given stable site order).
bool clusterSitesWithinMergeDistanceDegrees(
  double latA,
  double lngA,
  double latB,
  double lngB,
  double threshold,
) {
  final double dLat = latA - latB;
  final double dLng = lngA - lngB;
  return dLat * dLat + dLng * dLng <= 2 * threshold * threshold;
}

(String, int, int) _cellKeyParts(LatLng p, double cell) {
  if (cell <= 0) {
    return ('0,0', 0, 0);
  }
  final int ix = (p.latitude / cell).floor();
  final int iy = (p.longitude / cell).floor();
  return ('$ix,$iy', ix, iy);
}

void _registerBucketInCell(
  Map<String, Set<int>> cellToBuckets,
  LatLng p,
  double cell,
  int bucketIndex,
) {
  final String key = _cellKeyParts(p, cell).$1;
  cellToBuckets.putIfAbsent(key, () => <int>{}).add(bucketIndex);
}

Iterable<int> _candidateBucketIndices(
  LatLng point,
  double cell,
  Map<String, Set<int>> cellToBuckets,
) sync* {
  final (_, int ix, int iy) = _cellKeyParts(point, cell);
  for (int dx = -1; dx <= 1; dx++) {
    for (int dy = -1; dy <= 1; dy++) {
      final String k = '${ix + dx},${iy + dy}';
      final Set<int>? set = cellToBuckets[k];
      if (set == null) {
        continue;
      }
      for (final int bi in set) {
        yield bi;
      }
    }
  }
}

/// Greedy clustering used by the pollution map (pixel-threshold in degree space).
///
/// **Stable ordering**: [displayedSites] is sorted by [PollutionSite.id] before the
/// greedy pass so bucket membership is identical across devices for the same inputs.
///
/// **Spatial index**: when there are more than [_kGridClusterMinSites] sites with
/// coordinates, a fixed cell grid (cell size = [threshold]) narrows bucket checks
/// from O(buckets) toward O(1) per site while preserving the same merge predicate.
List<ClusterBucket> buildMapClusterBuckets({
  required List<PollutionSite> displayedSites,
  required Map<String, LatLng> coordinates,
  required double zoom,
  required double cameraCenterLat,
  required double cameraCenterLng,
  required String? selectedSiteId,
}) {
  assert(zoom.isFinite && cameraCenterLat.isFinite && cameraCenterLng.isFinite);
  final double threshold = mapClusterThresholdDegrees(zoom);
  final List<PollutionSite> ordered = List<PollutionSite>.from(displayedSites)
    ..sort((PollutionSite a, PollutionSite b) => a.id.compareTo(b.id));

  final List<ClusterBucket> buckets = <ClusterBucket>[];
  final Map<String, Set<int>> cellToBuckets = <String, Set<int>>{};
  final bool useGrid =
      ordered.length > _kGridClusterMinSites && threshold > 0;

  LatLng? coordOf(String id) => coordinates[id];

  for (final PollutionSite site in ordered) {
    final LatLng? point = coordOf(site.id);
    if (point == null) {
      continue;
    }

    if (site.id == selectedSiteId) {
      final int bi = buckets.length;
      buckets.add(ClusterBucket(center: point, sites: <PollutionSite>[site]));
      if (useGrid) {
        _registerBucketInCell(cellToBuckets, point, threshold, bi);
      }
      continue;
    }

    ClusterBucket? target;
    int? targetIndex;

    final Iterable<int> candidateIndices = useGrid
        ? _candidateBucketIndices(point, threshold, cellToBuckets)
        : Iterable<int>.generate(buckets.length);

    final Set<int> seenCandidate = <int>{};
    for (final int bi in candidateIndices) {
      if (!seenCandidate.add(bi)) {
        continue;
      }
      if (bi < 0 || bi >= buckets.length) {
        continue;
      }
      final ClusterBucket b = buckets[bi];
      if (b.sites.any((PollutionSite s) => s.id == selectedSiteId)) {
        continue;
      }
      for (final PollutionSite s in b.sites) {
        final LatLng? bp = coordOf(s.id);
        if (bp == null) {
          continue;
        }
        if (clusterSitesWithinMergeDistanceDegrees(
          point.latitude,
          point.longitude,
          bp.latitude,
          bp.longitude,
          threshold,
        )) {
          target = b;
          targetIndex = bi;
          break;
        }
      }
      if (target != null) {
        break;
      }
    }

    if (target == null) {
      final int bi = buckets.length;
      buckets.add(ClusterBucket(center: point, sites: <PollutionSite>[site]));
      if (useGrid) {
        _registerBucketInCell(cellToBuckets, point, threshold, bi);
      }
    } else {
      target.addSite(site, point);
      if (useGrid) {
        final int? ti = targetIndex;
        if (ti != null) {
          _registerBucketInCell(cellToBuckets, point, threshold, ti);
        }
      }
    }
  }

  return buckets;
}

/// Below this count, a plain scan over buckets is cheaper than the grid map.
const int _kGridClusterMinSites = 48;

/// Payload for [compute] when [displayedSites.length] exceeds [_kIsolateClusterThreshold].
@immutable
class MapClusterIsolateInput {
  const MapClusterIsolateInput({
    required this.displayedSites,
    required this.coordinates,
    required this.zoom,
    required this.cameraCenterLat,
    required this.cameraCenterLng,
    required this.selectedSiteId,
  });

  final List<PollutionSite> displayedSites;
  final Map<String, LatLng> coordinates;
  final double zoom;
  final double cameraCenterLat;
  final double cameraCenterLng;
  final String? selectedSiteId;
}

const int kMapClusterIsolateThreshold = 100;

/// Top-level for `compute` (must be global or static).
List<ClusterBucket> mapClusterBucketsIsolate(MapClusterIsolateInput input) {
  return buildMapClusterBuckets(
    displayedSites: input.displayedSites,
    coordinates: input.coordinates,
    zoom: input.zoom,
    cameraCenterLat: input.cameraCenterLat,
    cameraCenterLng: input.cameraCenterLng,
    selectedSiteId: input.selectedSiteId,
  );
}

@immutable
class _ClusterPoint {
  const _ClusterPoint({
    required this.siteId,
    required this.latitude,
    required this.longitude,
  });

  final String siteId;
  final double latitude;
  final double longitude;
}

List<Map<String, Object>> _clusterPointsIsolate(Map<String, Object> input) {
  final List<Map<String, Object>> rawPoints = (input['points'] as List<Object>)
      .cast<Map<String, Object>>();
  final String? selectedSiteId =
      (input['selectedSiteId'] as String).isEmpty ? null : input['selectedSiteId'] as String;
  final double zoom = input['zoom'] as double;
  final double threshold = mapClusterThresholdDegrees(zoom);
  rawPoints.sort(
    (Map<String, Object> a, Map<String, Object> b) =>
        (a['siteId'] as String).compareTo(b['siteId'] as String),
  );

  final List<List<_ClusterPoint>> grouped = <List<_ClusterPoint>>[];
  final Map<String, Set<int>> cellToBuckets = <String, Set<int>>{};
  final bool useGrid = rawPoints.length > _kGridClusterMinSites && threshold > 0;

  for (final Map<String, Object> raw in rawPoints) {
    final _ClusterPoint point = _ClusterPoint(
      siteId: raw['siteId'] as String,
      latitude: raw['latitude'] as double,
      longitude: raw['longitude'] as double,
    );

    if (point.siteId == selectedSiteId) {
      final int bi = grouped.length;
      grouped.add(<_ClusterPoint>[point]);
      if (useGrid) {
        _registerBucketInCell(
          cellToBuckets,
          LatLng(point.latitude, point.longitude),
          threshold,
          bi,
        );
      }
      continue;
    }

    List<_ClusterPoint>? target;
    int? targetIndex;

    final LatLng p = LatLng(point.latitude, point.longitude);
    final Iterable<int> candidateIndices = useGrid
        ? _candidateBucketIndices(p, threshold, cellToBuckets)
        : Iterable<int>.generate(grouped.length);

    final Set<int> seenCandidate = <int>{};
    for (final int bi in candidateIndices) {
      if (!seenCandidate.add(bi)) {
        continue;
      }
      if (bi < 0 || bi >= grouped.length) {
        continue;
      }
      final List<_ClusterPoint> bucket = grouped[bi];
      if (bucket.any((p0) => p0.siteId == selectedSiteId)) {
        continue;
      }
      for (final _ClusterPoint existing in bucket) {
        if (clusterSitesWithinMergeDistanceDegrees(
          point.latitude,
          point.longitude,
          existing.latitude,
          existing.longitude,
          threshold,
        )) {
          target = bucket;
          targetIndex = bi;
          break;
        }
      }
      if (target != null) {
        break;
      }
    }

    if (target == null) {
      final int bi = grouped.length;
      grouped.add(<_ClusterPoint>[point]);
      if (useGrid) {
        _registerBucketInCell(cellToBuckets, p, threshold, bi);
      }
    } else {
      target.add(point);
      if (useGrid) {
        final int? ti = targetIndex;
        if (ti != null) {
          _registerBucketInCell(cellToBuckets, p, threshold, ti);
        }
      }
    }
  }

  final List<Map<String, Object>> result = <Map<String, Object>>[];
  for (final List<_ClusterPoint> bucket in grouped) {
    double latSum = 0;
    double lngSum = 0;
    final List<String> siteIds = <String>[];
    for (final _ClusterPoint p in bucket) {
      latSum += p.latitude;
      lngSum += p.longitude;
      siteIds.add(p.siteId);
    }
    final int count = bucket.length;
    result.add(<String, Object>{
      'centerLat': latSum / count,
      'centerLng': lngSum / count,
      'siteIds': siteIds,
    });
  }
  return result;
}

Future<List<ClusterBucket>> buildMapClusterBucketsAdaptive({
  required List<PollutionSite> displayedSites,
  required Map<String, LatLng> coordinates,
  required double zoom,
  required double cameraCenterLat,
  required double cameraCenterLng,
  required String? selectedSiteId,
}) async {
  if (displayedSites.length <= kMapClusterIsolateThreshold) {
    return buildMapClusterBuckets(
      displayedSites: displayedSites,
      coordinates: coordinates,
      zoom: zoom,
      cameraCenterLat: cameraCenterLat,
      cameraCenterLng: cameraCenterLng,
      selectedSiteId: selectedSiteId,
    );
  }

  final Map<String, PollutionSite> sitesById = <String, PollutionSite>{
    for (final PollutionSite site in displayedSites) site.id: site,
  };
  final List<Map<String, Object>> points = <Map<String, Object>>[];
  for (final PollutionSite site in displayedSites) {
    final LatLng? point = coordinates[site.id];
    if (point == null) {
      continue;
    }
    points.add(<String, Object>{
      'siteId': site.id,
      'latitude': point.latitude,
      'longitude': point.longitude,
    });
  }
  final List<Map<String, Object>> rawBuckets = await compute(
    _clusterPointsIsolate,
    <String, Object>{
      'points': points,
      'selectedSiteId': selectedSiteId ?? '',
      'zoom': zoom,
    },
  );

  final List<ClusterBucket> buckets = <ClusterBucket>[];
  for (final Map<String, Object> raw in rawBuckets) {
    final List<String> ids = (raw['siteIds'] as List<Object>).cast<String>();
    final List<PollutionSite> bucketSites = ids
        .map((String id) => sitesById[id])
        .whereType<PollutionSite>()
        .toList();
    if (bucketSites.isEmpty) {
      continue;
    }
    buckets.add(
      ClusterBucket(
        center: LatLng(raw['centerLat'] as double, raw['centerLng'] as double),
        sites: bucketSites,
      ),
    );
  }
  return buckets;
}
