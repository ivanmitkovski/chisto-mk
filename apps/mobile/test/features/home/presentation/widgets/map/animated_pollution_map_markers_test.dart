import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/widgets/map/animated_pollution_map_markers.dart';
import 'package:feature_home/src/presentation/widgets/map/cluster_bucket.dart';
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
      ClusterBucket(
        center: const LatLng(41, 21),
        sites: <PollutionSite>[a],
        anchorId: 'a',
      ),
      ClusterBucket(
        center: const LatLng(41.1, 21.1),
        sites: <PollutionSite>[b],
        anchorId: 'b',
      ),
    ];
    final List<ClusterBucket> y = <ClusterBucket>[x[1], x[0]];
    expect(mapMarkerGeometrySignature(x), mapMarkerGeometrySignature(y));
  });

  test('mapMarkerGeometrySignature changes when center moves', () {
    final PollutionSite a = _site('a');
    final List<ClusterBucket> a1 = <ClusterBucket>[
      ClusterBucket(
        center: const LatLng(41, 21),
        sites: <PollutionSite>[a],
        anchorId: 'a',
      ),
    ];
    final List<ClusterBucket> a2 = <ClusterBucket>[
      ClusterBucket(
        center: const LatLng(41.02, 21),
        sites: <PollutionSite>[a],
        anchorId: 'a',
      ),
    ];
    expect(
      mapMarkerGeometrySignature(a1),
      isNot(mapMarkerGeometrySignature(a2)),
    );
  });

  test(
    'mapMarkerGeometrySignature is stable for anchorId across count change',
    () {
      final PollutionSite a = _site('a');
      final PollutionSite b = _site('b');
      final List<ClusterBucket> two = <ClusterBucket>[
        ClusterBucket(
          center: const LatLng(41, 21),
          sites: <PollutionSite>[a, b],
          anchorId: 'a',
        ),
      ];
      final List<ClusterBucket> one = <ClusterBucket>[
        ClusterBucket(
          center: const LatLng(41, 21),
          sites: <PollutionSite>[a, b, _site('c')],
          anchorId: 'a',
        ),
      ];
      final String sigTwo = mapMarkerGeometrySignature(two);
      final String sigOne = mapMarkerGeometrySignature(one);
      expect(sigTwo.contains('a@'), isTrue);
      expect(sigOne.contains('a@'), isTrue);
    },
  );
}
