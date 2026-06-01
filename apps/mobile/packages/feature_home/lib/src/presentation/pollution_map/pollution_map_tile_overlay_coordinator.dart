part of 'package:feature_home/src/presentation/pollution_map/pollution_map_screen.dart';

/// Tile loading overlay timers and dismiss logic for the pollution map.
class PollutionMapTileOverlayCoordinator {
  PollutionMapTileOverlayCoordinator({
    required this.isMounted,
    required this.onShowOverlayChanged,
    required this.readAnimatedMapController,
    required this.onCameraReady,
  });

  final bool Function() isMounted;
  // ignore: avoid_positional_boolean_parameters, callback signature
  final void Function(bool showOverlay) onShowOverlayChanged;
  final AnimatedMapController Function() readAnimatedMapController;
  final void Function(MapCamera camera) onCameraReady;

  bool showOverlay = true;
  bool mapLayoutReady = false;
  Timer? softDismissTimer;
  Timer? maxTimer;

  void onMapSurfaceReady() {
    if (!isMounted() || mapLayoutReady) return;
    mapLayoutReady = true;
    try {
      onCameraReady(readAnimatedMapController().mapController.camera);
    } catch (_) {
      // Camera not ready yet; clustering will sync on next stable map event.
    }
    softDismissTimer?.cancel();
    softDismissTimer = Timer(
      const Duration(milliseconds: 2600),
      dismissOverlay,
    );
    maxTimer?.cancel();
    maxTimer = Timer(const Duration(seconds: 14), dismissOverlay);
  }

  void scheduleDismissOnMapInteraction() {
    softDismissTimer?.cancel();
    softDismissTimer = Timer(const Duration(milliseconds: 400), dismissOverlay);
  }

  void dismissOverlay() {
    if (!showOverlay || !isMounted()) return;
    softDismissTimer?.cancel();
    maxTimer?.cancel();
    showOverlay = false;
    onShowOverlayChanged(false);
  }

  void dispose() {
    softDismissTimer?.cancel();
    maxTimer?.cancel();
  }
}
