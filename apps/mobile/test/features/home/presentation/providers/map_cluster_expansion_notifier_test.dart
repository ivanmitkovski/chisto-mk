import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_cluster_expansion_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/cluster_bucket.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

PollutionSite _site(String id) {
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
    latitude: 41.0,
    longitude: 21.0,
  );
}

void main() {
  test('beginExpansion clears ghost then expansion on timer schedule', () {
    fakeAsync((FakeAsync clock) {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final PollutionSite a = _site('a');
      final PollutionSite b = _site('b');
      final ClusterBucket bucket = ClusterBucket(
        center: const LatLng(41.0, 21.0),
        sites: <PollutionSite>[a, b],
      );
      final Map<String, LatLng> coords = <String, LatLng>{
        'a': const LatLng(41.0, 21.0),
        'b': const LatLng(41.0001, 21.0001),
      };

      container
          .read(mapClusterExpansionNotifierProvider.notifier)
          .beginExpansion(bucket: bucket, coordsById: coords);

      final MapClusterExpansionState s0 =
          container.read(mapClusterExpansionNotifierProvider);
      expect(s0.ghostCount, 2);
      expect(s0.expandingSiteIds, containsAll(<String>['a', 'b']));

      clock.elapse(AppMotion.mapClusterGhostClear);
      final MapClusterExpansionState s1 =
          container.read(mapClusterExpansionNotifierProvider);
      expect(s1.ghostCenter, isNull);
      expect(s1.expansionOrigin, isNotNull);

      clock.elapse(
        AppMotion.mapClusterExpansionHold - AppMotion.mapClusterGhostClear,
      );
      final MapClusterExpansionState s2 =
          container.read(mapClusterExpansionNotifierProvider);
      expect(s2.expansionOrigin, isNull);
      expect(s2.expandingSiteIds, isEmpty);
    });
  });

  test('rapid second beginExpansion bumps token and replaces expanding ids', () {
    fakeAsync((FakeAsync clock) {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final PollutionSite a = _site('a');
      final PollutionSite c = _site('c');
      final ClusterBucket bucket1 = ClusterBucket(
        center: const LatLng(41.0, 21.0),
        sites: <PollutionSite>[a],
      );
      final ClusterBucket bucket2 = ClusterBucket(
        center: const LatLng(42.0, 22.0),
        sites: <PollutionSite>[c],
      );
      final Map<String, LatLng> coords = <String, LatLng>{
        'a': const LatLng(41.0, 21.0),
        'c': const LatLng(42.0, 22.0),
      };

      final MapClusterExpansionNotifier n =
          container.read(mapClusterExpansionNotifierProvider.notifier);
      n.beginExpansion(bucket: bucket1, coordsById: coords);
      final int tokenAfterFirst =
          container.read(mapClusterExpansionNotifierProvider).expansionToken;
      n.beginExpansion(bucket: bucket2, coordsById: coords);
      final MapClusterExpansionState s =
          container.read(mapClusterExpansionNotifierProvider);
      expect(s.expansionToken, greaterThan(tokenAfterFirst));
      expect(s.expandingSiteIds, <String>{'c'});

      clock.elapse(AppMotion.mapClusterExpansionHold);
      expect(container.read(mapClusterExpansionNotifierProvider).expandingSiteIds,
          isEmpty);
    });
  });

  test('reset clears state and cancels pending timers', () {
    fakeAsync((FakeAsync clock) {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final PollutionSite a = _site('a');
      final ClusterBucket bucket = ClusterBucket(
        center: const LatLng(41.0, 21.0),
        sites: <PollutionSite>[a],
      );
      final Map<String, LatLng> coords = <String, LatLng>{
        'a': const LatLng(41.0, 21.0),
      };

      final MapClusterExpansionNotifier n =
          container.read(mapClusterExpansionNotifierProvider.notifier);
      n.beginExpansion(bucket: bucket, coordsById: coords);
      n.reset();

      expect(
        container.read(mapClusterExpansionNotifierProvider).expandingSiteIds,
        isEmpty,
      );
      clock.elapse(AppMotion.mapClusterExpansionHold * 2);
      expect(
        container.read(mapClusterExpansionNotifierProvider).expandingSiteIds,
        isEmpty,
      );
    });
  });
}
