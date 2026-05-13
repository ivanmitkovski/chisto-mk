import 'package:chisto_mobile/core/location/location_service.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/location_picker/location_picker_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLocationService implements LocationService {
  _FakeLocationService({
    required this.serviceEnabled,
    this.inFence = true,
  });

  final bool serviceEnabled;
  final bool inFence;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<AppLocationPermission> checkPermission() async =>
      AppLocationPermission.whileInUse;

  @override
  Future<AppLocationPermission> requestPermission() async =>
      AppLocationPermission.whileInUse;

  @override
  Future<GeoPosition> getCurrentPosition({
    required AppGeoAccuracy accuracy,
    Duration? timeLimit,
  }) async {
    if (!inFence) {
      return const GeoPosition(latitude: 0, longitude: 0);
    }
    return const GeoPosition(latitude: 41.9965, longitude: 21.4280);
  }

  @override
  Stream<GeoPosition> watchPosition({required GeoWatchOptions options}) {
    return const Stream<GeoPosition>.empty();
  }
}

void main() {
  test('detectCurrentLocation sets permissionUnavailable when service disabled', () async {
    final LocationPickerController c = LocationPickerController(
      locationService: _FakeLocationService(serviceEnabled: false),
      onLocationChanged: (_) {},
    );
    addTearDown(c.dispose);
    await c.detectCurrentLocation();
    expect(c.permissionUnavailable, isTrue);
    expect(c.resolvingGps, isFalse);
  });

  test('detectCurrentLocation sets gpsOutsideCoverage when outside geo fence', () async {
    final LocationPickerController c = LocationPickerController(
      locationService: _FakeLocationService(
        serviceEnabled: true,
        inFence: false,
      ),
      onLocationChanged: (_) {},
    );
    addTearDown(c.dispose);
    await c.detectCurrentLocation();
    expect(c.gpsOutsideCoverage, isTrue);
    expect(c.resolvingGps, isFalse);
  });
}
