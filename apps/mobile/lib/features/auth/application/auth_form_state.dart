import 'package:chisto_mobile/core/errors/app_error.dart';

/// Shared submit state for auth form notifiers.
class AuthFormState {
  const AuthFormState({
    this.isLoading = false,
    this.error,
  });

  final bool isLoading;
  final AppError? error;

  AuthFormState copyWith({
    bool? isLoading,
    AppError? error,
    bool clearError = false,
  }) {
    return AuthFormState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
