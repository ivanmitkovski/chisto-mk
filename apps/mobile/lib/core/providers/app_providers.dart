import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/core/storage/secure_token_storage.dart';
import 'package:chisto_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:chisto_mobile/features/onboarding/domain/feature_guide_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:chisto_mobile/core/providers/refresh_signals_providers.dart'
    show appLocaleOverrideProvider;

/// Root bootstrap singleton (constructed before [ProviderScope]).
final appBootstrapProvider = Provider<AppBootstrap>((Ref ref) {
  return AppBootstrap.instance;
});

final apiClientProvider = Provider<ApiClient>((Ref ref) {
  return ref.watch(appBootstrapProvider).apiClient;
});

final tokenStorageProvider = Provider<SecureTokenStorage>((Ref ref) {
  return ref.watch(appBootstrapProvider).tokenStorage;
});

/// Bridges [AppBootstrap] into Riverpod for auth and shared app services.
final authRepositoryProvider = Provider<AuthRepository>((Ref ref) {
  return ref.watch(appBootstrapProvider).authRepository;
});

final preferencesProvider = Provider<SharedPreferences>((Ref ref) {
  return ref.watch(appBootstrapProvider).preferences;
});

final featureGuideRepositoryProvider = Provider<FeatureGuideRepository>((Ref ref) {
  return ref.watch(appBootstrapProvider).featureGuideRepository;
});

final authStateProvider = Provider<AuthState>((Ref ref) {
  return ref.watch(appBootstrapProvider).authState;
});

final appConfigProvider = Provider<AppConfig>((Ref ref) {
  return ref.watch(appBootstrapProvider).config;
});
