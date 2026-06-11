import 'package:chisto_infrastructure/core/location/location_service.dart';

/// Best-effort device fix: medium-accuracy current position, then last-known fallback.
Future<GeoPosition?> readDeviceLocationFix(
  LocationService location, {
  Duration timeLimit = const Duration(seconds: 12),
}) async {
  try {
    return await location.getCurrentPosition(
      accuracy: AppGeoAccuracy.medium,
      timeLimit: timeLimit,
    );
  } catch (_) {
    if (location case LastKnownLocationReader reader) {
      try {
        return await reader.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
