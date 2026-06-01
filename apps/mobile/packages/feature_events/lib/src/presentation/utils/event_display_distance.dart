import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:latlong2/latlong.dart';

const Distance _distance = Distance();

/// Distance shown on discovery cards: prefer server [EcoEvent.siteDistanceKm],
/// otherwise haversine from the user hint to [EcoEvent.siteLat]/[EcoEvent.siteLng].
double? resolveEventDisplayDistanceKm(
  EcoEvent event, {
  required double? userLatitude,
  required double? userLongitude,
}) {
  if (event.siteDistanceKm > 0) {
    return event.siteDistanceKm;
  }
  final double? lat = userLatitude;
  final double? lng = userLongitude;
  final double? siteLat = event.siteLat;
  final double? siteLng = event.siteLng;
  if (lat == null || lng == null || siteLat == null || siteLng == null) {
    return null;
  }
  return _distance.as(
    LengthUnit.Kilometer,
    LatLng(lat, lng),
    LatLng(siteLat, siteLng),
  );
}
