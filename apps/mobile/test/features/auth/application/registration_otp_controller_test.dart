import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/auth/application/registration_otp_controller.dart';
import 'package:chisto_mobile/features/auth/presentation/constants/auth_otp_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';
import '../support/auth_test_helpers.dart';
import '../support/fake_auth_repository.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  test('verifyOtp locks after max invalid attempts', () async {
    final FakeAuthRepository repo = FakeAuthRepository()
      ..verifyOtpError = const AppError(code: 'OTP_INVALID', message: 'bad');

    final ProviderContainer container = ProviderContainer(
      overrides: AuthTestOverrides(authRepository: repo).build(),
    );
    addTearDown(container.dispose);

    final RegistrationOtpController notifier =
        container.read(registrationOtpControllerProvider.notifier);

    for (int i = 0; i < kAuthOtpMaxClientInvalidAttempts; i++) {
      await expectLater(
        notifier.verifyOtp('+38970123456', '000000'),
        throwsA(isA<AppError>()),
      );
    }

    final RegistrationOtpState state =
        container.read(registrationOtpControllerProvider);
    expect(state.otpLocked, isTrue);
    expect(state.verifyAttempts, kAuthOtpMaxClientInvalidAttempts);
    expect(state.error, isNull);
  });

  test('resetAttempts clears lock after max attempts', () async {
    final FakeAuthRepository repo = FakeAuthRepository()
      ..verifyOtpError = const AppError(code: 'OTP_INVALID', message: 'bad');

    final ProviderContainer container = ProviderContainer(
      overrides: AuthTestOverrides(authRepository: repo).build(),
    );
    addTearDown(container.dispose);

    final RegistrationOtpController notifier =
        container.read(registrationOtpControllerProvider.notifier);

    for (int i = 0; i < kAuthOtpMaxClientInvalidAttempts; i++) {
      await expectLater(
        notifier.verifyOtp('+38970123456', '000000'),
        throwsA(isA<AppError>()),
      );
    }
    notifier.resetAttempts();

    expect(container.read(registrationOtpControllerProvider).otpLocked, isFalse);
    expect(container.read(registrationOtpControllerProvider).verifyAttempts, 0);
  });
}
