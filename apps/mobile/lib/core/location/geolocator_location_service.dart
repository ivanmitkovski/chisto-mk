import 'package:chisto_mobile/core/location/location_service.dart';
import 'package:geolocator/geolocator.dart' as geo;

/// Production [LocationService] backed by the `geolocator` plugin.
class GeolocatorLocationService implements LocationService {
  @override
  Future<bool> isLocationServiceEnabled() {
    return geo.Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<AppLocationPermission> checkPermission() async {
    return _mapPermission(await geo.Geolocator.checkPermission());
  }

  @override
  Future<AppLocationPermission> requestPermission() async {
    return _mapPermission(await geo.Geolocator.requestPermission());
  }

  @override
  Future<GeoPosition> getCurrentPosition({
    required AppGeoAccuracy accuracy,
    Duration? timeLimit,
  }) async {
    final geo.Position pos = await geo.Geolocator.getCurrentPosition(
      desiredAccuracy: _toGeolocatorAccuracy(accuracy),
      timeLimit: timeLimit,
    );
    return GeoPosition(
      latitude: pos.latitude,
      longitude: pos.longitude,
      horizontalAccuracyMeters: pos.accuracy,
    );
  }

  @override
  Stream<GeoPosition> watchPosition({
    required GeoWatchOptions options,
  }) {
    final geo.LocationSettings settings = geo.LocationSettings(
      accuracy: _toGeolocatorAccuracy(options.accuracy),
      distanceFilter: options.distanceFilterMeters,
      timeLimit: options.timeLimit,
    );
    return geo.Geolocator.getPositionStream(locationSettings: settings).map(
      (geo.Position pos) => GeoPosition(
        latitude: pos.latitude,
        longitude: pos.longitude,
        horizontalAccuracyMeters: pos.accuracy,
      ),
    );
  }

  static AppLocationPermission _mapPermission(geo.LocationPermission p) {
    return switch (p) {
      geo.LocationPermission.denied => AppLocationPermission.denied,
      geo.LocationPermission.deniedForever =>
        AppLocationPermission.deniedForever,
      geo.LocationPermission.whileInUse => AppLocationPermission.whileInUse,
      geo.LocationPermission.always => AppLocationPermission.always,
      geo.LocationPermission.unableToDetermine =>
        AppLocationPermission.unableToDetermine,
    };
  }

  static geo.LocationAccuracy _toGeolocatorAccuracy(AppGeoAccuracy a) {
    return switch (a) {
      AppGeoAccuracy.lowest => geo.LocationAccuracy.lowest,
      AppGeoAccuracy.low => geo.LocationAccuracy.low,
      AppGeoAccuracy.medium => geo.LocationAccuracy.medium,
      AppGeoAccuracy.high => geo.LocationAccuracy.high,
      AppGeoAccuracy.best => geo.LocationAccuracy.best,
    };
  }
}
