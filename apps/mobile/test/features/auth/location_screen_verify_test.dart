import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/location/location_service.dart';
import 'package:feature_auth/src/presentation/screens/location_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/auth_test_helpers.dart';

class _OutsideMkLocationService implements LocationService {
  @override
  Future<AppLocationPermission> checkPermission() async =>
      AppLocationPermission.whileInUse;

  @override
  Future<GeoPosition> getCurrentPosition({
    required AppGeoAccuracy accuracy,
    Duration? timeLimit,
  }) async => const GeoPosition(latitude: 48.8566, longitude: 2.3522);

  @override
  Stream<GeoPosition> watchPosition({required GeoWatchOptions options}) =>
      const Stream<GeoPosition>.empty();

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<AppLocationPermission> requestPermission() async =>
      AppLocationPermission.whileInUse;
}

class _DeniedLocationService implements LocationService {
  @override
  Future<AppLocationPermission> checkPermission() async =>
      AppLocationPermission.denied;

  @override
  Future<GeoPosition> getCurrentPosition({
    required AppGeoAccuracy accuracy,
    Duration? timeLimit,
  }) async => const GeoPosition(latitude: 41.99, longitude: 21.43);

  @override
  Stream<GeoPosition> watchPosition({required GeoWatchOptions options}) =>
      const Stream<GeoPosition>.empty();

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<AppLocationPermission> requestPermission() async =>
      AppLocationPermission.denied;
}

void main() {
  setUp(() {
    AppBootstrap.instance.overrideLocationServiceForTests(
      _OutsideMkLocationService(),
    );
  });

  testWidgets('outside-Macedonia fix shows blocked state with retry', (
    WidgetTester tester,
  ) async {
    await authGoldenSurface(tester);
    await pumpAuthWidget(
      tester,
      home: const LocationScreen(),
      overrides: AuthTestOverrides().build(),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Use current location'));
    await tester.pumpAndSettle();

    expect(
      find.text('Chisto.mk is available in Macedonia'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Continue exploring'), findsNothing);
  });

  testWidgets('permission denied shows unavailable blocked state', (
    WidgetTester tester,
  ) async {
    await authGoldenSurface(tester);
    AppBootstrap.instance.overrideLocationServiceForTests(
      _DeniedLocationService(),
    );

    await pumpAuthWidget(
      tester,
      home: const LocationScreen(),
      overrides: AuthTestOverrides().build(),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Use current location'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining("couldn't confirm your location"),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });
}
