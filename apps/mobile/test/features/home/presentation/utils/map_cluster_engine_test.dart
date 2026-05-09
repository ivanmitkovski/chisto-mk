import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/utils/map_cluster_engine.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/cluster_bucket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

PollutionSite _site(String id, {double lat = 41.0, double lng = 21.0}) {
  return PollutionSite(
    id: id,
    title: 'Site $id',
    description: 'd',
    statusLabel: 'High',
    statusColor: Colors.red,
    distanceKm: 1,
    score: 1,
    participantCount: 0,
    mediaUrls: const <String>[],
    latitude: lat,
    longitude: lng,
  );
}

void main() {
  test('mapClusterThresholdDegrees decreases with zoom', () {
    final double low = mapClusterThresholdDegrees(8);
    final double high = mapClusterThresholdDegrees(16);
    expect(high, lessThan(low));
  });

  test('buildMapClusterBuckets returns empty for no sites', () {
    final List<ClusterBucket> buckets = buildMapClusterBuckets(
      displayedSites: const <PollutionSite>[],
      coordinates: const <String, LatLng>{},
      zoom: 12,
      cameraCenterLat: 41,
      cameraCenterLng: 21,
      selectedSiteId: null,
    );
    expect(buckets, isEmpty);
  });

  test('buildMapClusterBuckets skips sites missing coordinates', () {
    final PollutionSite s = _site('a');
    final List<ClusterBucket> buckets = buildMapClusterBuckets(
      displayedSites: <PollutionSite>[s],
      coordinates: const <String, LatLng>{},
      zoom: 12,
      cameraCenterLat: 41,
      cameraCenterLng: 21,
      selectedSiteId: null,
    );
    expect(buckets, isEmpty);
  });

  test('selected site is never merged into another bucket', () {
    final PollutionSite a = _site('a', lat: 41.0, lng: 21.0);
    final PollutionSite b = _site('b', lat: 41.00001, lng: 21.00001);
    final Map<String, LatLng> coords = <String, LatLng>{
      'a': LatLng(a.latitude!, a.longitude!),
      'b': LatLng(b.latitude!, b.longitude!),
    };
    final List<ClusterBucket> buckets = buildMapClusterBuckets(
      displayedSites: <PollutionSite>[a, b],
      coordinates: coords,
      zoom: 16,
      cameraCenterLat: 41,
      cameraCenterLng: 21,
      selectedSiteId: 'a',
    );
    expect(buckets.length, 2);
    expect(buckets.any((ClusterBucket c) => c.sites.length == 1 && c.sites.single.id == 'a'), isTrue);
  });

  test('buildMapClusterBuckets is independent of input site order', () {
    final PollutionSite a = _site('a', lat: 41.0, lng: 21.0);
    final PollutionSite b = _site('b', lat: 41.00001, lng: 21.00001);
    final PollutionSite c = _site('c', lat: 41.00002, lng: 21.00002);
    final Map<String, LatLng> coords = <String, LatLng>{
      'a': LatLng(a.latitude!, a.longitude!),
      'b': LatLng(b.latitude!, b.longitude!),
      'c': LatLng(c.latitude!, c.longitude!),
    };
    String signature(List<ClusterBucket> buckets) {
      final List<String> parts = buckets
          .map((ClusterBucket e) => e.stableClusterId)
          .toList()
        ..sort();
      return parts.join(';');
    }

    final List<ClusterBucket> forward = buildMapClusterBuckets(
      displayedSites: <PollutionSite>[a, b, c],
      coordinates: coords,
      zoom: 14,
      cameraCenterLat: 41,
      cameraCenterLng: 21,
      selectedSiteId: null,
    );
    final List<ClusterBucket> reversed = buildMapClusterBuckets(
      displayedSites: <PollutionSite>[c, a, b],
      coordinates: coords,
      zoom: 14,
      cameraCenterLat: 41,
      cameraCenterLng: 21,
      selectedSiteId: null,
    );
    expect(signature(forward), signature(reversed));
  });

  test('clusterSitesWithinMergeDistanceDegrees circumscribes legacy box', () {
    const double t = 0.01;
    expect(clusterSitesWithinMergeDistanceDegrees(0, 0, t, t, t), isTrue);
    expect(
      clusterSitesWithinMergeDistanceDegrees(0, 0, 1.2 * t, 0.5 * t, t),
      isTrue,
    );
    expect(
      clusterSitesWithinMergeDistanceDegrees(0, 0, 1.5 * t, 0.5 * t, t),
      isFalse,
    );
  });

  test('buildMapClusterBucketsAdaptive uses sync path at threshold', () async {
    final List<PollutionSite> sites = List<PollutionSite>.generate(
      kMapClusterIsolateThreshold,
      (int i) => _site('s$i', lat: 41.0 + i * 1e-4, lng: 21.0),
    );
    final Map<String, LatLng> coords = <String, LatLng>{
      for (final PollutionSite s in sites)
        if (s.latitude != null && s.longitude != null)
          s.id: LatLng(s.latitude!, s.longitude!),
    };
    final List<ClusterBucket> buckets = await buildMapClusterBucketsAdaptive(
      displayedSites: sites,
      coordinates: coords,
      zoom: 14,
      cameraCenterLat: 41,
      cameraCenterLng: 21,
      selectedSiteId: null,
    );
    expect(buckets.isNotEmpty, isTrue);
  });
}
