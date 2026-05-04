import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

import 'location_picker_geo_utils.dart';

/// Outcome of interpreting reverse-geocode placemarks for the report location picker.
class LocationPlacemarkSummary {
  const LocationPlacemarkSummary({
    required this.isMacedonia,
    required this.addressLine,
  });

  final bool isMacedonia;
  final String addressLine;
}

LocationPlacemarkSummary summarizePlacemarksForLocationPicker(
  List<Placemark> placemarks,
  LatLng position,
) {
  bool isMacedonia = false;
  bool addressSet = false;
  if (placemarks.isNotEmpty) {
    final Placemark p = placemarks.first;
    final List<String> parts = <String>[
      p.street ?? '',
      p.locality ?? '',
    ].where((String s) => s.trim().isNotEmpty).toList();
    final String countryName = (p.country ?? '').toLowerCase();
    final String? countryCode = p.isoCountryCode;
    isMacedonia =
        countryCode?.toUpperCase() == 'MK' ||
        countryName.contains('macedonia');
    if (parts.isNotEmpty) {
      addressSet = true;
    }
  }
  final String addressStr = addressSet && placemarks.isNotEmpty
      ? <String>[
          placemarks.first.street ?? '',
          placemarks.first.locality ?? '',
        ].where((String s) => s.trim().isNotEmpty).join(', ')
      : '';
  return LocationPlacemarkSummary(
    isMacedonia: isMacedonia,
    addressLine: addressStr.isNotEmpty
        ? addressStr
        : locationPickerCoordinateFallback(position),
  );
}
