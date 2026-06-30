/// Macedonia map bounds for event site pickers (shared with home/report maps).
class MacedoniaGeoFence {
  MacedoniaGeoFence._();

  static const double minLat = 40.8;
  static const double maxLat = 42.4;
  static const double minLng = 20.4;
  static const double maxLng = 23.1;

  static const double centerLat = 41.6086;
  static const double centerLng = 21.7453;

  static bool contains(double lat, double lng) {
    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }
}
