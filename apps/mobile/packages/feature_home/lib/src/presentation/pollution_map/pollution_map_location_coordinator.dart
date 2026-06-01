part of 'package:feature_home/src/presentation/pollution_map/pollution_map_screen.dart';

/// Foreground location tracking and locate-me camera moves for the pollution map.
mixin PollutionMapLocationCoordinator on ConsumerState<PollutionMapScreen> {
  Future<void> pollutionMapTryInitialLocate({
    required bool Function() hasAttemptedInitialLocate,
    // ignore: avoid_positional_boolean_parameters, callback signature
    required void Function(bool) setHasAttemptedInitialLocate,
    required AnimatedMapController animatedMapController,
    required void Function({required bool immediate}) syncMapViewport,
  }) async {
    if (hasAttemptedInitialLocate()) return;
    setHasAttemptedInitialLocate(true);
    final MapLocationNotifier notifier = ref.read(
      mapLocationNotifierProvider.notifier,
    );
    await notifier.tryInitialLocate();
    if (!mounted) return;
    final LatLng? location = ref.read(mapLocationNotifierProvider).userLocation;
    if (location != null) {
      await animatedMapController.animateTo(
        dest: location,
        zoom: MapLayoutTokens.zoomCity,
      );
      syncMapViewport(immediate: false);
      return;
    }
    final LocationService geo = ref.read(locationServiceProvider);
    if (await isLocationAccessBlocked(geo)) {
      if (!mounted) return;
      showLocationPermissionDeniedSnack(context);
    }
  }

  Future<void> pollutionMapHandleLocateMe({
    required AnimatedMapController animatedMapController,
    required void Function({required bool immediate}) syncMapViewport,
  }) async {
    final MapLocationNotifier notifier = ref.read(
      mapLocationNotifierProvider.notifier,
    );
    final GeoPosition? pos = await notifier.locateUserBest();
    if (!mounted) return;
    if (pos == null) {
      AppHaptics.warning(context);
      final LocationService geo = ref.read(locationServiceProvider);
      final bool permissionBlocked = await isLocationAccessBlocked(geo);
      if (!mounted) return;
      showMapLocateFailedSnack(context, permissionBlocked: permissionBlocked);
      return;
    }
    AppHaptics.success(context);
    await animatedMapController.animateTo(
      dest: LatLng(pos.latitude, pos.longitude),
      zoom: 16.5,
    );
    syncMapViewport(immediate: false);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      notifier.clearLocationJustFound();
    }
  }
}
