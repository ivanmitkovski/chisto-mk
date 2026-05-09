import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/animated_pollution_map_markers.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/cluster_bucket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

PollutionSite _site(String id) {
  return PollutionSite(
    id: id,
    title: id,
    description: 'd',
    statusLabel: 'High',
    statusColor: Colors.red,
    distanceKm: 1,
    score: 1,
    participantCount: 0,
    mediaUrls: const <String>[],
    latitude: 41,
    longitude: 21,
  );
}

void main() {
  test('mapMarkerGeometrySignature ignores bucket order', () {
    final PollutionSite a = _site('a');
    final PollutionSite b = _site('b');
    final List<ClusterBucket> x = <ClusterBucket>[
      ClusterBucket(center: const LatLng(41, 21), sites: <PollutionSite>[a]),
      ClusterBucket(center: const LatLng(41.1, 21.1), sites: <PollutionSite>[b]),
    ];
    final List<ClusterBucket> y = <ClusterBucket>[x[1], x[0]];
    expect(
      mapMarkerGeometrySignature(x),
      mapMarkerGeometrySignature(y),
    );
  });

  test('mapMarkerGeometrySignature changes when center moves', () {
    final PollutionSite a = _site('a');
    final List<ClusterBucket> a1 = <ClusterBucket>[
      ClusterBucket(center: const LatLng(41, 21), sites: <PollutionSite>[a]),
    ];
    final List<ClusterBucket> a2 = <ClusterBucket>[
      ClusterBucket(center: const LatLng(41.02, 21), sites: <PollutionSite>[a]),
    ];
    expect(
      mapMarkerGeometrySignature(a1),
      isNot(mapMarkerGeometrySignature(a2)),
    );
  });
}
