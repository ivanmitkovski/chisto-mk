import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/widgets/map/cluster_bucket.dart';
import 'package:feature_home/src/presentation/widgets/map/map_marker_entrance_cache.dart';
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
  late MapMarkerEntranceCache cache;

  setUp(() {
    cache = createMapMarkerEntranceCacheForTest();
  });

  test('clusterPartitionSignature is order-independent', () {
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
    expect(
      MapMarkerEntranceCache.clusterPartitionSignature(x),
      MapMarkerEntranceCache.clusterPartitionSignature(y),
    );
  });

  test(
    'applyReclusterEntranceInvalidations replays single entrance after multi',
    () {
      final PollutionSite a = _site('a');
      final PollutionSite b = _site('b');
      expect(cache.consumeSingleSiteEntrance('a'), isTrue);
      expect(cache.consumeSingleSiteEntrance('a'), isFalse);

      final List<ClusterBucket> prev = <ClusterBucket>[
        ClusterBucket(
          center: const LatLng(41, 21),
          sites: <PollutionSite>[a, b],
          anchorId: 'a',
        ),
      ];
      final List<ClusterBucket> next = <ClusterBucket>[
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
      cache.applyReclusterEntranceInvalidations(previous: prev, current: next);
      expect(cache.consumeSingleSiteEntrance('a'), isTrue);
      expect(cache.consumeSingleSiteEntrance('b'), isTrue);
    },
  );
}
