import 'package:chisto_mobile/core/providers/app_providers.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/auth/application/auth_form_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PasswordResetNewPasswordController extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }

  Future<void> confirmByPhone({
    required String phoneNumberE164,
    required String code,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).confirmPasswordReset(
            phoneNumberE164: phoneNumberE164,
            code: code,
            newPassword: newPassword,
          );
      state = state.copyWith(isLoading: false);
    } on AppError catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      rethrow;
    }
  }

  Future<void> confirmByEmail({
    required String token,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).confirmPasswordResetByEmail(
            token: token,
            newPassword: newPassword,
          );
      state = state.copyWith(isLoading: false);
    } on AppError catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      rethrow;
    }
  }
}

final passwordResetNewPasswordControllerProvider =
    NotifierProvider<PasswordResetNewPasswordController, AuthFormState>(
  PasswordResetNewPasswordController.new,
);
