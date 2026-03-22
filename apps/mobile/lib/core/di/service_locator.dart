import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/core/storage/secure_token_storage.dart';
import 'package:chisto_mobile/features/auth/data/api_auth_repository.dart';
import 'package:chisto_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:chisto_mobile/features/events/data/in_memory_events_store.dart';
import 'package:chisto_mobile/features/events/data/in_memory_check_in_repository.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/domain/repositories/check_in_repository.dart';
import 'package:chisto_mobile/features/profile/data/api_profile_repository.dart';
import 'package:chisto_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator instance = ServiceLocator._();

  AppConfig? _config;
  AuthState? _authState;
  SecureTokenStorage? _tokenStorage;
  SharedPreferences? _preferences;
  ApiClient? _apiClient;
  AuthRepository? _authRepository;
  EventsRepository? _eventsRepository;
  CheckInRepository? _checkInRepository;
  ProfileRepository? _profileRepository;

  AppConfig get config => _config!;
  AuthState get authState => _authState!;
  SecureTokenStorage get tokenStorage => _tokenStorage!;
  SharedPreferences get preferences => _preferences!;
  ApiClient get apiClient => _apiClient!;
  AuthRepository get authRepository => _authRepository!;
  EventsRepository get eventsRepository => _eventsRepository!;
  CheckInRepository get checkInRepository => _checkInRepository!;
  ProfileRepository get profileRepository => _profileRepository!;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> initialize({AppConfig? config}) async {
    if (_initialized) return;

    _config = config ?? AppConfig.fromEnvironment();
    _authState = AuthState();
    _tokenStorage = SecureTokenStorage();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _preferences = prefs;

    _apiClient = ApiClient(
      config: _config!,
      accessToken: () => _authState!.accessToken,
      onUnauthorized: () {
        _authState!.setUnauthenticated();
      },
    );

    _authRepository = ApiAuthRepository(
      client: _apiClient!,
      authState: _authState!,
      tokenStorage: _tokenStorage!,
      preferences: prefs,
    );

    _apiClient!.refreshSession = () async {
      try {
        await _authRepository!.refreshSession();
        return true;
      } on Exception catch (_) {
        return false;
      }
    };

    _eventsRepository = InMemoryEventsStore.instance;
    _checkInRepository = InMemoryCheckInRepository.instance;
    _profileRepository = ApiProfileRepository(client: _apiClient!);

    _initialized = true;
  }

  void reset() {
    _config = null;
    _authState = null;
    _tokenStorage = null;
    _preferences = null;
    _apiClient = null;
    _authRepository = null;
    _eventsRepository = null;
    _checkInRepository = null;
    _profileRepository = null;
    _initialized = false;
  }
}
