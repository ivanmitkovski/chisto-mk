import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:feature_auth/src/application/sign_in_controller.dart';
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

  test('rememberMe defaults to true when preference is unset', () {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ProviderContainer container = ProviderContainer(
      overrides: AuthTestOverrides().build(),
    );
    addTearDown(container.dispose);

    expect(container.read(signInControllerProvider).rememberMe, isTrue);
  });

  test('signIn stores error on failure', () async {
    final FakeAuthRepository repo = FakeAuthRepository()
      ..signInError = const AppError(code: 'INVALID_CREDENTIALS', message: 'x');
    final ProviderContainer container = ProviderContainer(
      overrides: AuthTestOverrides(authRepository: repo).build(),
    );
    addTearDown(container.dispose);

    await expectLater(
      container
          .read(signInControllerProvider.notifier)
          .signIn(phoneNumberE164: '+38970123456', password: 'secret'),
      throwsA(isA<AppError>()),
    );
    expect(
      container.read(signInControllerProvider).error?.code,
      'INVALID_CREDENTIALS',
    );
  });
}
