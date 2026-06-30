import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:feature_auth/src/application/auth_form_state.dart';
import 'package:feature_auth/src/domain/models/register_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignUpController extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }

  Future<RegisterResult> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumberE164,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final RegisterResult result = await ref
          .read(authRepositoryProvider)
          .signUp(
            firstName: firstName,
            lastName: lastName,
            email: email,
            phoneNumber: phoneNumberE164,
            password: password,
          );
      state = state.copyWith(isLoading: false);
      return result;
    } on AppError catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      rethrow;
    }
  }
}

final signUpControllerProvider =
    NotifierProvider<SignUpController, AuthFormState>(SignUpController.new);
