import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:feature_auth/src/application/initial_route_controller.dart';
import 'package:feature_auth/src/data/marketing_onboarding_store.dart';
import 'package:feature_auth/src/data/user_home_location_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/widget_test_bootstrap.dart';
import '../support/auth_test_helpers.dart';
import '../support/fake_auth_repository.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  tearDown(() async {
    InitialRouteController.pauseNavigation = false;
    AppBootstrap.instance.authState.setUnauthenticated();
    await UserHomeLocationStore.clearAllForSession(
      AppBootstrap.instance.preferences,
      userId: 'user-1',
    );
  });

  test('routes to signIn when onboarding completed and logged out', () async {
    await AppBootstrap.instance.preferences.setBool(
      kMarketingOnboardingCompletedKey,
      true,
    );
    AppBootstrap.instance.authState.setUnauthenticated();

    final ProviderContainer container = ProviderContainer(
      overrides: AuthTestOverrides(
        authRepository: FakeAuthRepository(),
      ).build(),
    );
    addTearDown(container.dispose);

    await container
        .read(initialRouteControllerProvider.notifier)
        .resolveRoute();

    expect(
      container.read(initialRouteControllerProvider).destination,
      InitialRouteDestination.signIn,
    );
  });

  test('routes to onboarding when marketing not completed', () async {
    await AppBootstrap.instance.preferences.setBool(
      kMarketingOnboardingCompletedKey,
      false,
    );
    AppBootstrap.instance.authState.setUnauthenticated();

    final ProviderContainer container = ProviderContainer(
      overrides: AuthTestOverrides(
        authRepository: FakeAuthRepository(),
      ).build(),
    );
    addTearDown(container.dispose);

    await container
        .read(initialRouteControllerProvider.notifier)
        .resolveRoute();

    expect(
      container.read(initialRouteControllerProvider).destination,
      InitialRouteDestination.onboarding,
    );
  });

  test(
    'routes to location gate when authenticated without home location',
    () async {
      await AppBootstrap.instance.preferences.setBool(
        kMarketingOnboardingCompletedKey,
        true,
      );
      AppBootstrap.instance.authState.setAuthenticated(
        userId: 'user-1',
        displayName: 'Test User',
      );
      await UserHomeLocationStore.clearAllForSession(
        AppBootstrap.instance.preferences,
        userId: 'user-1',
      );

      final ProviderContainer container = ProviderContainer(
        overrides: AuthTestOverrides(
          authRepository: FakeAuthRepository(isAuthenticated: true),
        ).build(),
      );
      addTearDown(container.dispose);

      await container
          .read(initialRouteControllerProvider.notifier)
          .resolveRoute();

      expect(
        container.read(initialRouteControllerProvider).destination,
        InitialRouteDestination.location,
      );
    },
  );

  test(
    'routes to home when authenticated with confirmed home location',
    () async {
      await AppBootstrap.instance.preferences.setBool(
        kMarketingOnboardingCompletedKey,
        true,
      );
      AppBootstrap.instance.authState.setAuthenticated(
        userId: 'user-1',
        displayName: 'Test User',
      );
      await UserHomeLocationStore(
        AppBootstrap.instance.preferences,
        userId: 'user-1',
      ).save(
        latitude: 41.9981,
        longitude: 21.4254,
        homeLocationSetAt: '2026-06-08T12:00:00.000Z',
      );

      final ProviderContainer container = ProviderContainer(
        overrides: AuthTestOverrides(
          authRepository: FakeAuthRepository(isAuthenticated: true),
        ).build(),
      );
      addTearDown(container.dispose);

      await container
          .read(initialRouteControllerProvider.notifier)
          .resolveRoute();

      expect(
        container.read(initialRouteControllerProvider).destination,
        InitialRouteDestination.home,
      );
    },
  );

  test(
    'routes to location gate when coords exist but home is unconfirmed',
    () async {
      await AppBootstrap.instance.preferences.setBool(
        kMarketingOnboardingCompletedKey,
        true,
      );
      AppBootstrap.instance.authState.setAuthenticated(
        userId: 'user-1',
        displayName: 'Test User',
      );
      await prefsLegacyCoordsOnly(AppBootstrap.instance.preferences);

      final ProviderContainer container = ProviderContainer(
        overrides: AuthTestOverrides(
          authRepository: FakeAuthRepository(isAuthenticated: true),
        ).build(),
      );
      addTearDown(container.dispose);

      await container
          .read(initialRouteControllerProvider.notifier)
          .resolveRoute();

      expect(
        container.read(initialRouteControllerProvider).destination,
        InitialRouteDestination.location,
      );
    },
  );
}

Future<void> prefsLegacyCoordsOnly(SharedPreferences prefs) async {
  await UserHomeLocationStore.clearAllForSession(prefs, userId: 'user-1');
  await prefs.setDouble(kUserHomeLatitudeKey, 41.99);
  await prefs.setDouble(kUserHomeLongitudeKey, 21.43);
}
