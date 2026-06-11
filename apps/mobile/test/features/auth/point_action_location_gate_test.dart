import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/location/location_service.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_auth/src/presentation/utils/auth_guard_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

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
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  group('ensureLocationEligibleForAction', () {
    testWidgets('proceeds when permission is denied (silent pass-through)', (
      WidgetTester tester,
    ) async {
      AppBootstrap.instance.overrideLocationServiceForTests(
        _DeniedLocationService(),
      );

      bool? gateResult;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: AppBootstrap.instance.providerContainer,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (BuildContext context, WidgetRef ref, Widget? child) {
                  return TextButton(
                    onPressed: () async {
                      gateResult = await ensureLocationEligibleForAction(
                        context,
                        ref,
                      );
                    },
                    child: const Text('gate'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('gate'));
      await tester.pumpAndSettle();

      expect(gateResult, isTrue);
      expect(find.text('Choose your location'), findsNothing);
    });

    testWidgets('blocks with snack when fix is outside Macedonia', (
      WidgetTester tester,
    ) async {
      AppBootstrap.instance.overrideLocationServiceForTests(
        _OutsideMkLocationService(),
      );

      bool? gateResult;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: AppBootstrap.instance.providerContainer,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (BuildContext context, WidgetRef ref, Widget? child) {
                  return TextButton(
                    onPressed: () async {
                      gateResult = await ensureLocationEligibleForAction(
                        context,
                        ref,
                      );
                    },
                    child: const Text('gate'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('gate'));
      await tester.pumpAndSettle();

      expect(gateResult, isFalse);
      expect(
        find.text('This action is only available in Macedonia.'),
        findsOneWidget,
      );
    });
  });

  group('handleLocationGuardError', () {
    testWidgets('shows snack for REPORT_LOCATION_OUTSIDE_MACEDONIA', (
      WidgetTester tester,
    ) async {
      bool handled = false;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: AppBootstrap.instance.providerContainer,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (BuildContext context, WidgetRef ref, Widget? child) {
                  return TextButton(
                    onPressed: () async {
                      handled = await handleLocationGuardError(
                        context,
                        ref,
                        const AppError(
                          code: 'REPORT_LOCATION_OUTSIDE_MACEDONIA',
                          message: 'blocked',
                        ),
                      );
                    },
                    child: const Text('error'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('error'));
      await tester.pumpAndSettle();

      expect(handled, isTrue);
      expect(
        find.text('This action is only available in Macedonia.'),
        findsOneWidget,
      );
    });
  });
}
