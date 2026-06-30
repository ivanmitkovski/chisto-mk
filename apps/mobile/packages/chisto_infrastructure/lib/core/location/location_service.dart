/// App-level permission result (decoupled from `geolocator` for tests and DI).
enum AppLocationPermission {
  denied,
  deniedForever,
  whileInUse,
  always,
  unableToDetermine,
}

/// Accuracy tier for a single fix (maps to `geolocator` [LocationAccuracy]).
enum AppGeoAccuracy { lowest, low, medium, high, best }

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
  const GeoPosition({
    required this.latitude,
    required this.longitude,
    this.horizontalAccuracyMeters,
    this.isMocked,
  });

  final double latitude;
  final double longitude;

  /// Best-effort horizontal accuracy in meters when the platform provides it.
  final double? horizontalAccuracyMeters;

  /// True when the platform reports a mocked/fake location (Android). Used as an
  /// anti-spoofing signal during location verification. Null when unknown (e.g. iOS).
  final bool? isMocked;
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
  Stream<GeoPosition> watchPosition({required GeoWatchOptions options});
}

/// Optional capability for platforms that cache a recent fix.
mixin LastKnownLocationReader on LocationService {
  Future<GeoPosition?> getLastKnownPosition();
}
