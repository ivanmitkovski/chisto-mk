import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_camera_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_clusters_provider.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_derived_providers.dart';

import '../support/settle_map_cluster_zoom.dart';
import '../support/test_pollution_site.dart';

void main() {
  test('clusters nearby sites into one bucket', () async {
    final siteA = buildTestPollutionSite(
      id: 'a',
      latitude: 41.60,
      longitude: 21.70,
    );
    final siteB = buildTestPollutionSite(
      id: 'b',
      latitude: 41.6002,
      longitude: 21.7002,
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        mapFilteredSitesProvider.overrideWithValue(<PollutionSite>[
          siteA,
          siteB,
        ]),
        mapSiteCoordinatesProvider.overrideWithValue(<String, LatLng>{
          'a': const LatLng(41.60, 21.70),
          'b': const LatLng(41.6002, 21.7002),
        }),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(mapCameraNotifierProvider.notifier)
        .setCamera(centerLat: 41.6, centerLng: 21.7, zoom: 15);
    await settleMapClusterEffectiveZoom(container, 15);
    final clusters = await container.read(mapClustersProvider.future);
    expect(clusters.length, 1);
    expect(clusters.first.sites.length, 2);
  });

  test('returns empty clusters for empty map sites', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        mapFilteredSitesProvider.overrideWithValue(const <PollutionSite>[]),
        mapSiteCoordinatesProvider.overrideWithValue(const <String, LatLng>{}),
      ],
    );
    addTearDown(container.dispose);
    final clusters = await container.read(mapClustersProvider.future);
    expect(clusters, isEmpty);
  });

  test('keeps non-overlapping sites in separate buckets', () async {
    final siteA = buildTestPollutionSite(
      id: 'a',
      latitude: 41.60,
      longitude: 21.70,
    );
    final siteB = buildTestPollutionSite(
      id: 'b',
      latitude: 42.10,
      longitude: 22.30,
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        mapFilteredSitesProvider.overrideWithValue(<PollutionSite>[
          siteA,
          siteB,
        ]),
        mapSiteCoordinatesProvider.overrideWithValue(<String, LatLng>{
          'a': const LatLng(41.60, 21.70),
          'b': const LatLng(42.10, 22.30),
        }),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(mapCameraNotifierProvider.notifier)
        .setCamera(centerLat: 41.6, centerLng: 21.7, zoom: 15);
    await settleMapClusterEffectiveZoom(container, 15);
    final clusters = await container.read(mapClustersProvider.future);
    expect(clusters.length, 2);
    expect(clusters.every((bucket) => bucket.sites.length == 1), isTrue);
  });
}
