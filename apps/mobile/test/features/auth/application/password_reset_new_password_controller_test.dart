import 'package:feature_auth/src/application/password_reset_new_password_controller.dart';
import 'package:feature_auth/src/domain/models/password_reset_target.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';
import '../support/auth_test_helpers.dart';
import '../support/fake_auth_repository.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  test('confirm with SMS target completes without error', () async {
    var called = false;
    final FakeAuthRepository repo = FakeAuthRepository(
      confirmPasswordResetImpl:
          ({
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
        .confirm(
          target: const PasswordResetTarget(
            channel: PasswordResetChannel.sms,
            value: '+38970123456',
          ),
          code: '123456',
          newPassword: 'newpass123',
        );

    expect(called, isTrue);
    expect(
      container.read(passwordResetNewPasswordControllerProvider).isLoading,
      isFalse,
    );
  });

  test('confirm with email target calls repository', () async {
    var called = false;
    final FakeAuthRepository repo = FakeAuthRepository(
      confirmPasswordResetByEmailImpl:
          ({
            required String email,
            required String code,
            required String newPassword,
          }) async {
            called = true;
            expect(email, 'user@example.com');
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
        .confirm(
          target: const PasswordResetTarget(
            channel: PasswordResetChannel.email,
            value: 'user@example.com',
          ),
          code: '123456',
          newPassword: 'newpass123',
        );

    expect(called, isTrue);
  });
}
