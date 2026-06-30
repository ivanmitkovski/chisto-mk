import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:feature_auth/src/application/auth_form_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeLocationController extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }

  Future<void> saveHomeLocation({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .updateHomeLocation(
            latitude: latitude,
            longitude: longitude,
            label: label,
          );
      await ref
          .read(featureGuideRepositoryProvider)
          .markPostRegistrationGuidePending();
      state = state.copyWith(isLoading: false);
    } on AppError catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      rethrow;
    }
  }
}

final homeLocationControllerProvider =
    NotifierProvider<HomeLocationController, AuthFormState>(
      HomeLocationController.new,
    );
