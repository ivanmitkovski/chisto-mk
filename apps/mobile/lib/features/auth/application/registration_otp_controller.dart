import 'package:chisto_mobile/core/providers/app_providers.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/auth/application/auth_form_state.dart';
import 'package:chisto_mobile/features/auth/presentation/constants/auth_otp_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegistrationOtpState extends AuthFormState {
  const RegistrationOtpState({
    super.isLoading,
    super.error,
    this.sendingOtp = false,
    this.verifyAttempts = 0,
    this.otpLocked = false,
  });

  final bool sendingOtp;
  final int verifyAttempts;
  final bool otpLocked;

  @override
  RegistrationOtpState copyWith({
    bool? isLoading,
    AppError? error,
    bool clearError = false,
    bool? sendingOtp,
    int? verifyAttempts,
    bool? otpLocked,
  }) {
    return RegistrationOtpState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      sendingOtp: sendingOtp ?? this.sendingOtp,
      verifyAttempts: verifyAttempts ?? this.verifyAttempts,
      otpLocked: otpLocked ?? this.otpLocked,
    );
  }
}

class RegistrationOtpController extends Notifier<RegistrationOtpState> {
  @override
  RegistrationOtpState build() => const RegistrationOtpState();

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }

  Future<void> requestOtp(String phoneNumberE164) async {
    if (state.sendingOtp) return;
    state = state.copyWith(sendingOtp: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).requestOtp(phoneNumberE164);
      state = state.copyWith(sendingOtp: false);
    } on AppError catch (e) {
      state = state.copyWith(sendingOtp: false, error: e);
    }
  }

  Future<void> verifyOtp(String phoneNumberE164, String code) async {
    if (state.otpLocked || state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).verifyOtp(phoneNumberE164, code);
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

  void resetAttempts() {
    state = state.copyWith(
      verifyAttempts: 0,
      otpLocked: false,
      clearError: true,
    );
  }
}

final registrationOtpControllerProvider = NotifierProvider<RegistrationOtpController,
    RegistrationOtpState>(RegistrationOtpController.new);
