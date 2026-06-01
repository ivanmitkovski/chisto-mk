import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:feature_auth/src/application/initial_route_controller.dart';
import 'package:feature_auth/src/data/marketing_onboarding_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';
import '../support/auth_test_helpers.dart';
import '../support/fake_auth_repository.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  tearDown(() {
    InitialRouteController.pauseNavigation = false;
    AppBootstrap.instance.authState.setUnauthenticated();
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
}
