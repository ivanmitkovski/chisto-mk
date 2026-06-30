import 'package:chisto_infrastructure/core/location/location_service.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_home/src/presentation/location_permission_ui.dart';
import 'package:feature_home/src/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _DeniedLocationService implements LocationService {
  @override
  Future<AppLocationPermission> checkPermission() async =>
      AppLocationPermission.deniedForever;

  @override
  Future<GeoPosition> getCurrentPosition({
    required AppGeoAccuracy accuracy,
    Duration? timeLimit,
  }) async => const GeoPosition(latitude: 0, longitude: 0);

  @override
  Stream<GeoPosition> watchPosition({required GeoWatchOptions options}) =>
      const Stream<GeoPosition>.empty();

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<AppLocationPermission> requestPermission() async =>
      AppLocationPermission.deniedForever;
}

void main() {
  test(
    'isLocationAccessBlocked is true when permission denied forever',
    () async {
      final bool blocked = await isLocationAccessBlocked(
        _DeniedLocationService(),
      );
      expect(blocked, isTrue);
    },
  );

  testWidgets('showLocationPermissionDeniedSnack shows Open Settings action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          locationServiceProvider.overrideWithValue(_DeniedLocationService()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (BuildContext context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () => showLocationPermissionDeniedSnack(context),
                  child: const Text('trigger'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('trigger'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Open Settings'), findsOneWidget);

    // Let the snack's auto-dismiss timer (4s for action snacks) fire so no
    // timers are pending when the widget tree is disposed.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
