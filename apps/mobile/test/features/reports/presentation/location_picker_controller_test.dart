import 'package:chisto_infrastructure/core/location/location_service.dart';
import 'package:feature_home/src/application/home_providers.dart';
import 'package:feature_reports/src/presentation/widgets/location_picker/location_picker_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

class _FakeLocationService implements LocationService {
  _FakeLocationService({required this.serviceEnabled, this.inFence = true});

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

ProviderContainer _container(_FakeLocationService locationService) {
  return ProviderContainer(
    overrides: <Override>[
      locationServiceProvider.overrideWithValue(locationService),
    ],
  );
}

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  test(
    'detectCurrentLocation sets permissionUnavailable when service disabled',
    () async {
      final ProviderContainer container = _container(
        _FakeLocationService(serviceEnabled: false),
      );
      addTearDown(container.dispose);
      final LocationPickerController notifier = container.read(
        locationPickerControllerProvider(null, null).notifier,
      );
      await notifier.detectCurrentLocation();
      final LocationPickerState state = container.read(
        locationPickerControllerProvider(null, null),
      );
      expect(state.permissionUnavailable, isTrue);
      expect(state.resolvingGps, isFalse);
    },
  );

  test(
    'detectCurrentLocation sets gpsOutsideCoverage when outside geo fence',
    () async {
      final ProviderContainer container = _container(
        _FakeLocationService(serviceEnabled: true, inFence: false),
      );
      addTearDown(container.dispose);
      final LocationPickerController notifier = container.read(
        locationPickerControllerProvider(null, null).notifier,
      );
      await notifier.detectCurrentLocation();
      final LocationPickerState state = container.read(
        locationPickerControllerProvider(null, null),
      );
      expect(state.gpsOutsideCoverage, isTrue);
      expect(state.resolvingGps, isFalse);
    },
  );

  test(
    'stable provider family keeps street zoom when draft coords would change key',
    () {
      const double kLat = 41.99;
      const double kLng = 21.43;
      final ProviderContainer container = _container(
        _FakeLocationService(serviceEnabled: true),
      );
      addTearDown(container.dispose);
      final LocationPickerControllerProvider stable =
          locationPickerControllerProvider(kLat, kLng);
      final LocationPickerController notifier = container.read(stable.notifier);
      notifier.startInitialFlow(initialLatitude: kLat, initialLongitude: kLng);
      expect(container.read(stable).currentZoom, 16);

      final LocationPickerControllerProvider shifted =
          locationPickerControllerProvider(kLat + 0.01, kLng + 0.01);
      expect(container.read(shifted).currentZoom, 7);

      expect(container.read(stable).currentZoom, 16);
    },
  );
}
