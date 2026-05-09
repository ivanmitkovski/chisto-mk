/// App-level permission result (decoupled from `geolocator` for tests and DI).
enum AppLocationPermission {
  denied,
  deniedForever,
  whileInUse,
  always,
  unableToDetermine,
}

/// Accuracy tier for a single fix (maps to `geolocator` [LocationAccuracy]).
enum AppGeoAccuracy {
  lowest,
  low,
  medium,
  high,
  best,
}

/// Stream configuration for foreground location tracking.
class GeoWatchOptions {
  const GeoWatchOptions({
    required this.accuracy,
    this.distanceFilterMeters = 15,
    this.timeLimit,
  });

  final AppGeoAccuracy accuracy;
  final int distanceFilterMeters;
  final Duration? timeLimit;
}

/// A single latitude/longitude reading from the platform.
class GeoPosition {
  const GeoPosition({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// Abstraction over device location APIs for map, feed, and tests.
abstract class LocationService {
  Future<bool> isLocationServiceEnabled();

  Future<AppLocationPermission> checkPermission();

  Future<AppLocationPermission> requestPermission();

  Future<GeoPosition> getCurrentPosition({
    required AppGeoAccuracy accuracy,
    Duration? timeLimit,
  });

  /// Foreground-only position stream.
  Stream<GeoPosition> watchPosition({
    required GeoWatchOptions options,
  });
}
