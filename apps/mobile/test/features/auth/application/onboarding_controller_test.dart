import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:feature_auth/src/application/onboarding_controller.dart';
import 'package:feature_auth/src/data/marketing_onboarding_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';
import '../support/auth_test_helpers.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  test('completeOnboarding marks marketing onboarding completed', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: AuthTestOverrides().build(),
    );
    addTearDown(container.dispose);

    await container
        .read(onboardingControllerProvider.notifier)
        .completeOnboarding();

    expect(
      AppBootstrap.instance.preferences.getBool(
        kMarketingOnboardingCompletedKey,
      ),
      isTrue,
    );
  });
}
