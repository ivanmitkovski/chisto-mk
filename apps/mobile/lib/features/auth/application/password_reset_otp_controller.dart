import 'package:chisto_mobile/core/providers/app_providers.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/auth/application/auth_form_state.dart';
import 'package:chisto_mobile/features/auth/presentation/constants/auth_otp_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PasswordResetOtpState extends AuthFormState {
  const PasswordResetOtpState({
    super.isLoading,
    super.error,
    this.verifyAttempts = 0,
    this.otpLocked = false,
  });

  final int verifyAttempts;
  final bool otpLocked;

  @override
  PasswordResetOtpState copyWith({
    bool? isLoading,
    AppError? error,
    bool clearError = false,
    int? verifyAttempts,
    bool? otpLocked,
  }) {
    return PasswordResetOtpState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      verifyAttempts: verifyAttempts ?? this.verifyAttempts,
      otpLocked: otpLocked ?? this.otpLocked,
    );
  }
}

class PasswordResetOtpController extends Notifier<PasswordResetOtpState> {
  @override
  PasswordResetOtpState build() => const PasswordResetOtpState();

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }

  Future<void> verifyCode(String phoneE164, String code) async {
    if (state.otpLocked || state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyPasswordResetCode(phoneE164, code);
      state = state.copyWith(isLoading: false);
    } on AppError catch (e) {
      if (e.code == 'OTP_INVALID') {
        final int attempts = state.verifyAttempts + 1;
        final bool locked = attempts >= kAuthOtpMaxClientInvalidAttempts;
        state = state.copyWith(
          isLoading: false,
          error: locked ? null : e,
          verifyAttempts: attempts,
          otpLocked: locked,
        );
      } else {
        state = state.copyWith(isLoading: false, error: e);
      }
      rethrow;
    }
  }

  Future<void> resend(String phoneE164) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(phoneE164);
      state = state.copyWith(
        isLoading: false,
        verifyAttempts: 0,
        otpLocked: false,
        clearError: true,
      );
    } on AppError catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      rethrow;
    }
  }

  void resetAttempts() {
    state = state.copyWith(
      verifyAttempts: 0,
      otpLocked: false,
      clearError: true,
    );
  }
}

final passwordResetOtpControllerProvider =
    NotifierProvider<PasswordResetOtpController, PasswordResetOtpState>(
  PasswordResetOtpController.new,
);
