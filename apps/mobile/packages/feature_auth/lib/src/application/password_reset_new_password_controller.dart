import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:feature_auth/src/application/auth_form_state.dart';
import 'package:feature_auth/src/domain/models/password_reset_target.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PasswordResetNewPasswordController extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }

  Future<void> confirm({
    required PasswordResetTarget target,
    required String code,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(authRepositoryProvider);
      if (target.isSms) {
        await repo.confirmPasswordReset(
          phoneNumberE164: target.value,
          code: code,
          newPassword: newPassword,
        );
      } else {
        await repo.confirmPasswordResetByEmail(
          email: target.value,
          code: code,
          newPassword: newPassword,
        );
      }
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
