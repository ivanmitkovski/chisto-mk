import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:feature_auth/src/application/auth_form_state.dart';
import 'package:feature_auth/src/domain/models/password_reset_target.dart';
import 'package:feature_auth/src/presentation/constants/auth_otp_constants.dart';
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

  Future<void> verifyCode(PasswordResetTarget target, String code) async {
    if (state.otpLocked || state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(authRepositoryProvider);
      if (target.isSms) {
        await repo.verifyPasswordResetCode(target.value, code);
      } else {
        await repo.verifyPasswordResetCodeByEmail(target.value, code);
      }
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

  Future<void> resend(PasswordResetTarget target) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(authRepositoryProvider);
      if (target.isSms) {
        await repo.requestPasswordReset(target.value);
      } else {
        await repo.requestPasswordResetByEmail(target.value);
      }
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
