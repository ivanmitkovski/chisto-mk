import 'package:chisto_mobile/features/auth/application/splash_session_controller.dart';
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
    SplashSessionController.pauseAfterRestore = false;
  });

  test('restoreSession sets completed after restore', () async {
    var restored = false;
    final FakeAuthRepository repo = FakeAuthRepository(
      restoreSessionImpl: () async {
        restored = true;
      },
    );
    final ProviderContainer container = ProviderContainer(
      overrides: AuthTestOverrides(authRepository: repo).build(),
    );
    addTearDown(container.dispose);

    await container
        .read(splashSessionControllerProvider.notifier)
        .restoreSession();

    expect(restored, isTrue);
    expect(container.read(splashSessionControllerProvider).completed, isTrue);
    expect(container.read(splashSessionControllerProvider).isRestoring, isFalse);
  });

  test('pauseAfterRestore skips completed flag', () async {
    SplashSessionController.pauseAfterRestore = true;
    final ProviderContainer container = ProviderContainer(
      overrides: AuthTestOverrides(authRepository: FakeAuthRepository()).build(),
    );
    addTearDown(container.dispose);

    await container
        .read(splashSessionControllerProvider.notifier)
        .restoreSession();

    expect(container.read(splashSessionControllerProvider).completed, isFalse);
  });
}
