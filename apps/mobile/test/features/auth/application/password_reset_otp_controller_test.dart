import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:feature_auth/src/application/password_reset_otp_controller.dart';
import 'package:feature_auth/src/presentation/constants/auth_otp_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';
import '../support/auth_test_helpers.dart';
import '../support/fake_auth_repository.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  test('verifyCode surfaces OTP_INVALID as error state', () async {
    final FakeAuthRepository repo = FakeAuthRepository()
      ..verifyPasswordResetCodeError = const AppError(
        code: 'OTP_INVALID',
        message: 'bad',
      );
    final ProviderContainer container = ProviderContainer(
      overrides: AuthTestOverrides(authRepository: repo).build(),
    );
    addTearDown(container.dispose);

    await expectLater(
      container
          .read(passwordResetOtpControllerProvider.notifier)
          .verifyCode('+38970123456', '000000'),
      throwsA(isA<AppError>()),
    );
    expect(
      container.read(passwordResetOtpControllerProvider).error?.code,
      'OTP_INVALID',
    );
  });

  test('verifyCode locks after max invalid attempts', () async {
    final FakeAuthRepository repo = FakeAuthRepository()
      ..verifyPasswordResetCodeError = const AppError(
        code: 'OTP_INVALID',
        message: 'bad',
      );
    final ProviderContainer container = ProviderContainer(
      overrides: AuthTestOverrides(authRepository: repo).build(),
    );
    addTearDown(container.dispose);

    final PasswordResetOtpController notifier = container.read(
      passwordResetOtpControllerProvider.notifier,
    );

    for (int i = 0; i < kAuthOtpMaxClientInvalidAttempts; i++) {
      await expectLater(
        notifier.verifyCode('+38970123456', '000000'),
        throwsA(isA<AppError>()),
      );
    }

    final PasswordResetOtpState state = container.read(
      passwordResetOtpControllerProvider,
    );
    expect(state.otpLocked, isTrue);
    expect(state.error, isNull);
  });
}
