/// Single source of truth for Macedonia bounds (axis-aligned box).
/// Matches server [MACEDONIA_BOUNDS] in apps/api.
class MacedoniaBounds {
  static const double minLat = 40.8;
  static const double maxLat = 42.4;
  static const double minLng = 20.4;
  static const double maxLng = 23.1;

  static bool contains(double latitude, double longitude) {
    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= minLat &&
        latitude <= maxLat &&
        longitude >= minLng &&
        longitude <= maxLng;
  }
}

bool isWithinMacedonia(double latitude, double longitude) =>
    MacedoniaBounds.contains(latitude, longitude);
