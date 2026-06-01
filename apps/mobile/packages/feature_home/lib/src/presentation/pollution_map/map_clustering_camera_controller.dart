import 'dart:async';

import 'package:feature_home/src/presentation/providers/map_camera_notifier.dart';
import 'package:feature_home/src/presentation/providers/map_cluster_effective_zoom_notifier.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Debounces [mapCameraNotifierProvider] writes during map gestures so clustering
/// does not rebuild on every drag frame.
class MapClusteringCameraController {
  MapClusteringCameraController({required this.ref, required this.isMounted});

  final WidgetRef ref;
  final bool Function() isMounted;

  Timer? _clusteringDebounce;

  void dispose() {
    _clusteringDebounce?.cancel();
  }

  void commitCamera(MapCamera cam) {
    if (!isMounted()) {
      return;
    }
    ref
        .read(mapCameraNotifierProvider.notifier)
        .setCamera(
          centerLat: cam.center.latitude,
          centerLng: cam.center.longitude,
          zoom: cam.zoom,
        );
  }

  void debounceCommit(MapCamera cam, Duration delay) {
    _clusteringDebounce?.cancel();
    _clusteringDebounce = Timer(delay, () {
      _clusteringDebounce = null;
      if (!isMounted()) {
        return;
      }
      commitCamera(cam);
    });
  }

  /// Feeds clustering/heatmap keyed providers when movement settles.
  void handleMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd ||
        event is MapEventFlingAnimationEnd ||
        event is MapEventDoubleTapZoomEnd ||
        event is MapEventRotateEnd ||
        event is MapEventFlingAnimationNotStarted) {
      _clusteringDebounce?.cancel();
      _clusteringDebounce = null;
      commitCamera(event.camera);
      return;
    }

    if (event is MapEventNonRotatedSizeChange ||
        event is MapEventScrollWheelZoom) {
      debounceCommit(event.camera, const Duration(milliseconds: 160));
      return;
    }

    if (event is MapEventMove && event.source == MapEventSource.onMultiFinger) {
      debounceCommit(event.camera, const Duration(milliseconds: 46));
      return;
    }

    if (event is MapEventMove && event.source == MapEventSource.mapController) {
      debounceCommit(event.camera, const Duration(milliseconds: 200));
    }
  }

  /// Immediately commits target camera and jumps effective clustering zoom.
  void preCommitTargetCamera(double centerLat, double centerLng, double zoom) {
    if (!isMounted()) {
      return;
    }
    _clusteringDebounce?.cancel();
    _clusteringDebounce = null;
    ref.read(mapClusterEffectiveZoomProvider.notifier).jumpTo(zoom);
    ref
        .read(mapCameraNotifierProvider.notifier)
        .setCamera(centerLat: centerLat, centerLng: centerLng, zoom: zoom);
  }
}
