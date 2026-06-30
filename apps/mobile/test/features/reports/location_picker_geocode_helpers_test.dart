import 'package:feature_reports/src/presentation/widgets/location_picker/location_picker_geo_utils.dart';
import 'package:feature_reports/src/presentation/widgets/location_picker/location_picker_geocode_helpers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('summarizePlacemarksForLocationPicker', () {
    test('detects MK via ISO country code', () {
      final LocationPlacemarkSummary s =
          summarizePlacemarksForLocationPicker(<Placemark>[
            const Placemark(
              isoCountryCode: 'MK',
              country: 'North Macedonia',
              street: 'Skopska',
              locality: 'Skopje',
            ),
          ], const LatLng(41.99, 21.43));
      expect(s.isMacedonia, isTrue);
      expect(s.addressLine, contains('Skopje'));
    });

    test('detects MK via country name substring', () {
      final LocationPlacemarkSummary s = summarizePlacemarksForLocationPicker(
        <Placemark>[const Placemark(country: 'Republic of North Macedonia')],
        const LatLng(41, 21),
      );
      expect(s.isMacedonia, isTrue);
    });

    test('uses coordinate fallback when placemarks empty', () {
      const LatLng p = LatLng(40.1, 22);
      final LocationPlacemarkSummary s = summarizePlacemarksForLocationPicker(
        <Placemark>[],
        p,
      );
      expect(s.isMacedonia, isFalse);
      expect(s.addressLine, locationPickerCoordinateFallback(p));
    });
  });

  group('locationPickerSameLatLng', () {
    test('treats nearly identical points as equal', () {
      expect(
        locationPickerSameLatLng(
          const LatLng(41, 21),
          const LatLng(41.00005, 21.00005),
        ),
        isTrue,
      );
    });
  });
}
