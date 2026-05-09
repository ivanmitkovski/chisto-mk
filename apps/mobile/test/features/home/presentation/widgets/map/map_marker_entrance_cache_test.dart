import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/cluster_bucket.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_marker_entrance_cache.dart';
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
  setUp(MapMarkerEntranceCache.instance.clear);

  test('clusterPartitionSignature is order-independent', () {
    final PollutionSite a = _site('a');
    final PollutionSite b = _site('b');
    final List<ClusterBucket> x = <ClusterBucket>[
      ClusterBucket(center: const LatLng(41, 21), sites: <PollutionSite>[a]),
      ClusterBucket(center: const LatLng(41.1, 21.1), sites: <PollutionSite>[b]),
    ];
    final List<ClusterBucket> y = <ClusterBucket>[x[1], x[0]];
    expect(
      MapMarkerEntranceCache.clusterPartitionSignature(x),
      MapMarkerEntranceCache.clusterPartitionSignature(y),
    );
  });

  test('applyReclusterEntranceInvalidations replays single entrance after multi', () {
    final PollutionSite a = _site('a');
    final PollutionSite b = _site('b');
    final MapMarkerEntranceCache c = MapMarkerEntranceCache.instance;
    expect(c.consumeSingleSiteEntrance('a'), isTrue);
    expect(c.consumeSingleSiteEntrance('a'), isFalse);

    final List<ClusterBucket> prev = <ClusterBucket>[
      ClusterBucket(
        center: const LatLng(41, 21),
        sites: <PollutionSite>[a, b],
      ),
    ];
    final List<ClusterBucket> next = <ClusterBucket>[
      ClusterBucket(center: const LatLng(41, 21), sites: <PollutionSite>[a]),
      ClusterBucket(center: const LatLng(41.1, 21.1), sites: <PollutionSite>[b]),
    ];
    c.applyReclusterEntranceInvalidations(previous: prev, current: next);
    expect(c.consumeSingleSiteEntrance('a'), isTrue);
    expect(c.consumeSingleSiteEntrance('b'), isTrue);
  });
}
