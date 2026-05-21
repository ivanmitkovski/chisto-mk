import 'package:chisto_mobile/core/providers/app_providers.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/auth/application/auth_form_state.dart';
import 'package:chisto_mobile/features/auth/domain/models/register_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PasswordResetRequestController extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }

  Future<PasswordResetRequestResult> requestByPhone(String phoneE164) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final PasswordResetRequestResult result = await ref
          .read(authRepositoryProvider)
          .requestPasswordReset(phoneE164);
      state = state.copyWith(isLoading: false);
      return result;
    } on AppError catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      rethrow;
    }
  }

  Future<PasswordResetRequestResult> requestByEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final PasswordResetRequestResult result = await ref
          .read(authRepositoryProvider)
          .requestPasswordResetByEmail(email);
      state = state.copyWith(isLoading: false);
      return result;
    } on AppError catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      rethrow;
    }
  }
}

final passwordResetRequestControllerProvider =
    NotifierProvider<PasswordResetRequestController, AuthFormState>(
  PasswordResetRequestController.new,
);
