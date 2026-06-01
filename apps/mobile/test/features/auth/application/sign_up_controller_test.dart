import 'package:feature_auth/src/application/sign_up_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';
import '../support/auth_test_helpers.dart';
import '../support/fake_auth_repository.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  test('signUp returns register result on success', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: AuthTestOverrides(
        authRepository: FakeAuthRepository(),
      ).build(),
    );
    addTearDown(container.dispose);

    final result = await container
        .read(signUpControllerProvider.notifier)
        .signUp(
          firstName: 'Test',
          lastName: 'User',
          email: 't@example.com',
          phoneNumberE164: '+38970123456',
          password: 'password123',
        );

    expect(result.phoneNumber, '+38970123456');
    expect(container.read(signUpControllerProvider).isLoading, isFalse);
  });
}
