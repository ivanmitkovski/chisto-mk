import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:chisto_mobile/core/location/location_service.dart';
import 'package:chisto_mobile/features/home/presentation/providers/repository_providers.dart';

class MapLocationState {
  const MapLocationState({
    this.userLocation,
    this.isLocating = false,
    this.isTracking = false,
    this.locationJustFound = false,
  });

  final LatLng? userLocation;
  final bool isLocating;
  final bool isTracking;
  final bool locationJustFound;

  MapLocationState copyWith({
    LatLng? userLocation,
    bool? isLocating,
    bool? isTracking,
    bool? locationJustFound,
    bool clearUserLocation = false,
  }) {
    return MapLocationState(
      userLocation: clearUserLocation ? null : (userLocation ?? this.userLocation),
      isLocating: isLocating ?? this.isLocating,
      isTracking: isTracking ?? this.isTracking,
      locationJustFound: locationJustFound ?? this.locationJustFound,
    );
  }
}

final mapLocationNotifierProvider =
    NotifierProvider<MapLocationNotifier, MapLocationState>(
  MapLocationNotifier.new,
);

class MapLocationNotifier extends Notifier<MapLocationState> {
  static const GeoWatchOptions _trackingOptions = GeoWatchOptions(
    accuracy: AppGeoAccuracy.medium,
    distanceFilterMeters: 18,
    timeLimit: Duration(seconds: 10),
  );
  static const Duration _minTrackingUpdateInterval = Duration(seconds: 2);
  static const double _minTrackingMoveMeters = 8;

  final Distance _distance = const Distance();
  bool _initialLocateAttempted = false;
  StreamSubscription<GeoPosition>? _trackingSub;
  DateTime? _lastTrackingUpdateAt;
  LatLng? _lastTrackedLocation;

  @override
  MapLocationState build() {
    ref.onDispose(() {
      unawaited(_trackingSub?.cancel());
      _trackingSub = null;
    });
    return const MapLocationState();
  }

  /// One-shot startup locate (medium accuracy, short timeout) — failures are silent.
  Future<void> tryInitialLocate() async {
    if (_initialLocateAttempted) {
      return;
    }
    _initialLocateAttempted = true;
    final LocationService geo = ref.read(locationServiceProvider);
    try {
      if (!await geo.isLocationServiceEnabled()) {
        return;
      }
      AppLocationPermission permission = await geo.checkPermission();
      if (permission == AppLocationPermission.denied) {
        permission = await geo.requestPermission();
      }
      if (permission != AppLocationPermission.whileInUse &&
          permission != AppLocationPermission.always) {
        return;
      }
      final GeoPosition pos = await geo.getCurrentPosition(
        accuracy: AppGeoAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
      state = state.copyWith(
        userLocation: LatLng(pos.latitude, pos.longitude),
      );
    } on Exception catch (_) {
      // Stay at country / default view.
    }
  }

  /// High-accuracy locate for the FAB; sets [isLocating] / [locationJustFound].
  Future<GeoPosition?> locateUserBest() async {
    if (state.isLocating) {
      return null;
    }
    state = state.copyWith(isLocating: true, locationJustFound: false);
    final LocationService geo = ref.read(locationServiceProvider);
    try {
      if (!await geo.isLocationServiceEnabled()) {
        state = state.copyWith(isLocating: false);
        return null;
      }
      AppLocationPermission permission = await geo.checkPermission();
      if (permission == AppLocationPermission.denied) {
        permission = await geo.requestPermission();
      }
      if (permission == AppLocationPermission.denied ||
          permission == AppLocationPermission.deniedForever) {
        state = state.copyWith(isLocating: false);
        return null;
      }
      final GeoPosition pos = await geo.getCurrentPosition(
        accuracy: AppGeoAccuracy.best,
        timeLimit: const Duration(seconds: 12),
      );
      state = state.copyWith(
        userLocation: LatLng(pos.latitude, pos.longitude),
        isLocating: false,
        locationJustFound: true,
      );
      return pos;
    } on Exception catch (_) {
      state = state.copyWith(isLocating: false);
      return null;
    }
  }

  Future<bool> startForegroundTracking() async {
    if (_trackingSub != null) {
      if (!state.isTracking) {
        state = state.copyWith(isTracking: true);
      }
      return true;
    }
    final LocationService geo = ref.read(locationServiceProvider);
    try {
      if (!await geo.isLocationServiceEnabled()) {
        state = state.copyWith(isTracking: false);
        return false;
      }
      AppLocationPermission permission = await geo.checkPermission();
      if (permission == AppLocationPermission.denied) {
        permission = await geo.requestPermission();
      }
      if (permission != AppLocationPermission.whileInUse &&
          permission != AppLocationPermission.always) {
        state = state.copyWith(isTracking: false);
        return false;
      }
      _trackingSub = geo
          .watchPosition(options: _trackingOptions)
          .listen(_onTrackedPosition, onError: (_, _) {});
      state = state.copyWith(isTracking: true);
      return true;
    } on Exception catch (_) {
      state = state.copyWith(isTracking: false);
      return false;
    }
  }

  Future<void> stopForegroundTracking() async {
    await _trackingSub?.cancel();
    _trackingSub = null;
    _lastTrackingUpdateAt = null;
    _lastTrackedLocation = null;
    if (state.isTracking) {
      state = state.copyWith(isTracking: false);
    }
  }

  void clearLocationJustFound() {
    if (state.locationJustFound) {
      state = state.copyWith(locationJustFound: false);
    }
  }

  void _onTrackedPosition(GeoPosition pos) {
    final LatLng next = LatLng(pos.latitude, pos.longitude);
    final DateTime now = DateTime.now();
    final DateTime? previousAt = _lastTrackingUpdateAt;
    final LatLng? previousLoc = _lastTrackedLocation;
    if (previousAt != null &&
        previousLoc != null &&
        now.difference(previousAt) < _minTrackingUpdateInterval) {
      final double movedMeters = _distance.as(
        LengthUnit.Meter,
        previousLoc,
        next,
      );
      if (movedMeters < _minTrackingMoveMeters) {
        return;
      }
    }
    _lastTrackingUpdateAt = now;
    _lastTrackedLocation = next;
    state = state.copyWith(
      userLocation: next,
      locationJustFound: false,
      isTracking: true,
    );
  }
}
