import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:feature_auth/src/application/auth_form_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String kRememberMeKey = 'chisto_remember_me';
const String kLastSignInPhoneKey = 'chisto_last_signin_phone';

class SignInState extends AuthFormState {
  const SignInState({
    super.isLoading,
    super.error,
    this.rememberMe = false,
    this.lastPhoneNational,
  });

  final bool rememberMe;
  final String? lastPhoneNational;

  @override
  SignInState copyWith({
    bool? isLoading,
    AppError? error,
    bool clearError = false,
    bool? rememberMe,
    String? lastPhoneNational,
    bool clearLastPhone = false,
  }) {
    return SignInState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      rememberMe: rememberMe ?? this.rememberMe,
      lastPhoneNational: clearLastPhone
          ? null
          : (lastPhoneNational ?? this.lastPhoneNational),
    );
  }
}

class SignInController extends Notifier<SignInState> {
  @override
  SignInState build() {
    final prefs = ref.read(preferencesProvider);
    final bool rememberMe = prefs.getBool(kRememberMeKey) ?? true;
    final String? lastPhone = prefs.getString(kLastSignInPhoneKey);
    return SignInState(
      rememberMe: rememberMe,
      lastPhoneNational: rememberMe && lastPhone != null && lastPhone.isNotEmpty
          ? formatPhoneNationalPart(lastPhone)
          : null,
    );
  }

  void setRememberMe({required bool value}) {
    state = state.copyWith(rememberMe: value, clearError: true);
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }

  Future<void> signIn({
    required String phoneNumberE164,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(
            phoneNumber: phoneNumberE164,
            password: password,
            rememberMe: state.rememberMe,
          );
      await _saveRememberMe(phoneE164: phoneNumberE164);
      state = state.copyWith(isLoading: false);
    } on AppError catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      rethrow;
    }
  }

  Future<void> _saveRememberMe({required String phoneE164}) async {
    final prefs = ref.read(preferencesProvider);
    await prefs.setBool(kRememberMeKey, state.rememberMe);
    if (state.rememberMe) {
      await prefs.setString(kLastSignInPhoneKey, phoneE164);
    } else {
      await prefs.remove(kLastSignInPhoneKey);
    }
  }
}

final signInControllerProvider =
    NotifierProvider<SignInController, SignInState>(SignInController.new);
