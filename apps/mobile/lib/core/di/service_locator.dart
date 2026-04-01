import 'dart:async';

import 'package:flutter/foundation.dart';

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
import 'package:chisto_mobile/features/home/data/api_sites_repository.dart';
import 'package:chisto_mobile/features/home/data/map_realtime/map_realtime_service.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository.dart';
import 'package:chisto_mobile/features/notifications/data/api_notifications_repository.dart';
import 'package:chisto_mobile/features/notifications/data/push_notification_service.dart';
import 'package:chisto_mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:chisto_mobile/features/profile/data/api_profile_repository.dart';
import 'package:chisto_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:chisto_mobile/features/reports/data/api_reports_repository.dart';
import 'package:chisto_mobile/features/reports/data/reports_realtime/reports_realtime_service.dart';
import 'package:chisto_mobile/features/reports/domain/repositories/reports_api_repository.dart';
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
  AuthRepository? _authRepositoryForUnauthorized;
  EventsRepository? _eventsRepository;
  CheckInRepository? _checkInRepository;
  ProfileRepository? _profileRepository;
  ReportsApiRepository? _reportsApiRepository;
  ReportsRealtimeService? _reportsRealtimeService;
  SitesRepository? _sitesRepository;
  MapRealtimeService? _mapRealtimeService;
  NotificationsRepository? _notificationsRepository;
  PushNotificationService? _pushNotificationService;

  /// Increment to trigger profile refresh (e.g. after report submit).
  final ValueNotifier<int> profileNeedsRefresh = ValueNotifier<int>(0);

  AppConfig get config => _config!;
  AuthState get authState => _authState!;
  SecureTokenStorage get tokenStorage => _tokenStorage!;
  SharedPreferences get preferences => _preferences!;
  ApiClient get apiClient => _apiClient!;
  AuthRepository get authRepository => _authRepository!;
  EventsRepository get eventsRepository => _eventsRepository!;
  CheckInRepository get checkInRepository => _checkInRepository!;
  ProfileRepository get profileRepository => _profileRepository!;
  ReportsApiRepository get reportsApiRepository => _reportsApiRepository!;
  ReportsRealtimeService get reportsRealtimeService => _reportsRealtimeService!;
  SitesRepository get sitesRepository => _sitesRepository!;
  MapRealtimeService get mapRealtimeService => _mapRealtimeService!;
  NotificationsRepository get notificationsRepository =>
      _notificationsRepository!;
  PushNotificationService get pushNotificationService =>
      _pushNotificationService!;

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
        final AuthRepository? repo = _authRepositoryForUnauthorized;
        if (repo != null) {
          unawaited(repo.invalidateLocalSession());
        } else {
          _authState!.setUnauthenticated();
        }
      },
    );

    _notificationsRepository = ApiNotificationsRepository(client: _apiClient!);
    _pushNotificationService = PushNotificationService(
      repository: _notificationsRepository!,
    );

    _authRepository = ApiAuthRepository(
      client: _apiClient!,
      authState: _authState!,
      tokenStorage: _tokenStorage!,
      preferences: prefs,
      pushService: _pushNotificationService,
    );
    _authRepositoryForUnauthorized = _authRepository;

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
    _reportsApiRepository = ApiReportsRepository(client: _apiClient!);
    _reportsRealtimeService = ReportsRealtimeService(
      config: _config!,
      authState: _authState!,
    );
    _mapRealtimeService = MapRealtimeService(
      config: _config!,
      authState: _authState!,
    );
    _sitesRepository = ApiSitesRepository(client: _apiClient!);

    _initialized = true;
  }

  void reset() {
    _reportsRealtimeService?.dispose();
    _mapRealtimeService?.dispose();
    _pushNotificationService?.dispose();
    _config = null;
    _authState = null;
    _tokenStorage = null;
    _preferences = null;
    _apiClient = null;
    _authRepository = null;
    _authRepositoryForUnauthorized = null;
    _eventsRepository = null;
    _checkInRepository = null;
    _profileRepository = null;
    _reportsApiRepository = null;
    _reportsRealtimeService = null;
    _mapRealtimeService = null;
    _sitesRepository = null;
    _notificationsRepository = null;
    _pushNotificationService = null;
    _initialized = false;
  }
}
