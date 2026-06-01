import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:feature_auth/src/application/password_reset_request_controller.dart';
import 'package:feature_auth/src/domain/models/register_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';
import '../support/auth_test_helpers.dart';
import '../support/fake_auth_repository.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  test('requestByPhone returns result on success', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: AuthTestOverrides(
        authRepository: FakeAuthRepository(),
      ).build(),
    );
    addTearDown(container.dispose);

    final PasswordResetRequestResult result = await container
        .read(passwordResetRequestControllerProvider.notifier)
        .requestByPhone('+38970123456');

    expect(result.message, 'ok');
    expect(
      container.read(passwordResetRequestControllerProvider).isLoading,
      isFalse,
    );
  });

  test('requestByEmail stores error on failure', () async {
    final FakeAuthRepository repo = FakeAuthRepository(
      requestPasswordResetByEmailImpl: (_) async {
        throw const AppError(code: 'USER_NOT_FOUND', message: 'x');
      },
    );
    final ProviderContainer container = ProviderContainer(
      overrides: AuthTestOverrides(authRepository: repo).build(),
    );
    addTearDown(container.dispose);

    await expectLater(
      container
          .read(passwordResetRequestControllerProvider.notifier)
          .requestByEmail('a@b.com'),
      throwsA(isA<AppError>()),
    );
    expect(
      container.read(passwordResetRequestControllerProvider).error?.code,
      'USER_NOT_FOUND',
    );
  });
}
