import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/auth/application/password_reset_new_password_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';
import '../support/auth_test_helpers.dart';
import '../support/fake_auth_repository.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  test('confirmByPhone completes without error', () async {
    var called = false;
    final FakeAuthRepository repo = FakeAuthRepository(
      confirmPasswordResetImpl: ({
        required String phoneNumberE164,
        required String code,
        required String newPassword,
      }) async {
        called = true;
        expect(phoneNumberE164, '+38970123456');
        expect(code, '123456');
        expect(newPassword, 'newpass123');
      },
    );

    final ProviderContainer container = ProviderContainer(
      overrides: AuthTestOverrides(authRepository: repo).build(),
    );
    addTearDown(container.dispose);

    await container
        .read(passwordResetNewPasswordControllerProvider.notifier)
        .confirmByPhone(
          phoneNumberE164: '+38970123456',
          code: '123456',
          newPassword: 'newpass123',
        );

    expect(called, isTrue);
    expect(
      container.read(passwordResetNewPasswordControllerProvider).isLoading,
      isFalse,
    );
  });

  test('confirmByEmail calls repository', () async {
    var called = false;
    final FakeAuthRepository repo = FakeAuthRepository(
      confirmPasswordResetByEmailImpl: ({
        required String token,
        required String newPassword,
      }) async {
        called = true;
        expect(token, 'email-tok');
        expect(newPassword, 'newpass123');
      },
    );

    final ProviderContainer container = ProviderContainer(
      overrides: AuthTestOverrides(authRepository: repo).build(),
    );
    addTearDown(container.dispose);

    await container
        .read(passwordResetNewPasswordControllerProvider.notifier)
        .confirmByEmail(token: 'email-tok', newPassword: 'newpass123');

    expect(called, isTrue);
  });
}
