import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_camera_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_cluster_effective_zoom_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_derived_providers.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_selection_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/utils/map_cluster_engine.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/cluster_bucket.dart';

class MapClusterInput {
  const MapClusterInput({
    required this.sites,
    required this.coordsById,
    required this.zoom,
    required this.center,
    required this.selectedId,
  });

  final List<PollutionSite> sites;
  final Map<String, LatLng> coordsById;
  final double zoom;
  final LatLng center;
  final String? selectedId;
}

/// Quantized smooth clustering zoom → stable bucket rebuilds between ramp steps.
final mapClusterComputationZoomProvider = Provider<double>((Ref ref) {
  final double raw = ref.watch(mapClusterEffectiveZoomProvider);
  return quantizeZoomForClusterRecompute(raw);
});

final mapClusterInputProvider = Provider<MapClusterInput>((Ref ref) {
  final List<PollutionSite> filtered = ref.watch(mapFilteredSitesProvider);
  final Map<String, LatLng> coords = ref.watch(mapSiteCoordinatesProvider);
  final MapCameraState camera = ref.watch(mapCameraNotifierProvider);
  final double clusteringZoom = ref.watch(mapClusterComputationZoomProvider);
  final String? selectedId = ref.watch(
    mapSelectionNotifierProvider.select(
      (MapSelectionState s) => s.selected?.id,
    ),
  );
  return MapClusterInput(
    sites: filtered,
    coordsById: coords,
    zoom: clusteringZoom,
    center: LatLng(camera.centerLat, camera.centerLng),
    selectedId: selectedId,
  );
});

/// Stable hash so clustering work does not re-run when unrelated map UI state changes.
final mapClusterComputationKeyProvider = Provider<int>((Ref ref) {
  final List<PollutionSite> filtered = ref.watch(mapFilteredSitesProvider);
  final MapCameraState camera = ref.watch(mapCameraNotifierProvider);
  final double clusteringZoom = ref.watch(mapClusterComputationZoomProvider);
  final String? selectedId = ref.watch(
    mapSelectionNotifierProvider.select(
      (MapSelectionState s) => s.selected?.id,
    ),
  );
  return Object.hash(
    Object.hashAll(
      filtered.map(
        (PollutionSite s) => Object.hash(
          s.id,
          s.latitude?.toStringAsFixed(5),
          s.longitude?.toStringAsFixed(5),
        ),
      ),
    ),
    (clusteringZoom * 10000).round(),
    selectedId,
    (camera.centerLat * 1000).round(),
    (camera.centerLng * 1000).round(),
  );
});

final mapClustersProvider = FutureProvider<List<ClusterBucket>>((
  Ref ref,
) async {
  ref.watch(mapClusterComputationKeyProvider);
  final MapClusterInput input = ref.read(mapClusterInputProvider);
  return buildMapClusterBucketsAdaptive(
    displayedSites: input.sites,
    coordinates: input.coordsById,
    zoom: input.zoom,
    cameraCenterLat: input.center.latitude,
    cameraCenterLng: input.center.longitude,
    selectedSiteId: input.selectedId,
  );
});
