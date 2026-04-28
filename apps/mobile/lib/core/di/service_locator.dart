import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/l10n/app_locale_resolution.dart';
import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/core/storage/secure_token_storage.dart';
import 'package:chisto_mobile/features/auth/data/api_auth_repository.dart';
import 'package:chisto_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:chisto_mobile/features/events/data/api_check_in_repository.dart';
import 'package:chisto_mobile/features/events/data/api_events_repository.dart';
import 'package:chisto_mobile/features/events/data/api_event_analytics_repository.dart';
import 'package:chisto_mobile/features/events/data/chat/api_event_chat_repository.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_repository.dart';
import 'package:chisto_mobile/features/events/data/check_in_sync_service.dart';
import 'package:chisto_mobile/features/events/data/event_offline_work_coordinator.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/domain/repositories/check_in_repository.dart';
import 'package:chisto_mobile/features/home/data/api_sites_repository.dart';
import 'package:chisto_mobile/features/home/data/engagement_outbox_coordinator.dart';
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

  static const String _appLocaleCodeKey = 'app_locale_code';

  /// Non-null: user chose a fixed app language. Null: follow device locale (with [supported] fallback).
  final ValueNotifier<Locale?> appLocaleOverride = ValueNotifier<Locale?>(null);

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
  ApiEventAnalyticsRepository? _eventAnalyticsRepository;
  EventChatRepository? _eventChatRepository;

  /// Increment to trigger profile refresh (e.g. after report submit).
  final ValueNotifier<int> profileNeedsRefresh = ValueNotifier<int>(0);

  /// Increment when a server push implies the public events list should refresh (e.g. new published cleanup).
  final ValueNotifier<int> eventsFeedRemoteRefreshTick = ValueNotifier<int>(0);

  AppConfig get config => _config!;
  AuthState? get authStateOrNull => _authState;
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

  ApiEventAnalyticsRepository get eventAnalyticsRepository =>
      _eventAnalyticsRepository!;

  EventChatRepository get eventChatRepository => _eventChatRepository!;

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
      acceptLanguageHeader: () {
        final Locale effective = resolveAppLocale(
          override: appLocaleOverride.value,
          platformLocales: PlatformDispatcher.instance.locales,
        );
        return acceptLanguageFromLocale(effective);
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

    final ApiEventsRepository eventsRepo =
        ApiEventsRepository(client: _apiClient!);
    _eventsRepository = eventsRepo;
    _checkInRepository = ApiCheckInRepository(
      client: _apiClient!,
      eventsRepository: eventsRepo,
    );
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
    _sitesRepository = ApiSitesRepository(
      client: _apiClient!,
      authState: _authState!,
    );
    unawaited(
      EngagementOutboxCoordinator.start(
        sitesRepository: _sitesRepository!,
        authState: _authState!,
      ),
    );
    _eventAnalyticsRepository = ApiEventAnalyticsRepository(client: _apiClient!);
    _eventChatRepository = ApiEventChatRepository(
      client: _apiClient!,
      config: _config!,
      authState: _authState!,
    );

    // Start offline check-in sync service (drains queued payloads on connectivity restore).
    unawaited(
      CheckInSyncService.start(
        client: _apiClient!,
        eventsRepository: _eventsRepository!,
        checkInRepository: _checkInRepository!,
      ),
    );

    unawaited(EventOfflineWorkCoordinator.instance.start());

    _loadStoredAppLocale(prefs);

    _initialized = true;
  }

  void _loadStoredAppLocale(SharedPreferences prefs) {
    final String? code = prefs.getString(_appLocaleCodeKey);
    if (code == 'en') {
      appLocaleOverride.value = const Locale('en');
    } else if (code == 'mk') {
      appLocaleOverride.value = const Locale('mk');
    } else if (code == 'sq') {
      appLocaleOverride.value = const Locale('sq');
    } else {
      appLocaleOverride.value = null;
    }
  }

  /// Persists choice. Pass [null] to use device language.
  Future<void> setAppLocale(Locale? locale) async {
    final SharedPreferences prefs = _preferences!;
    if (locale == null) {
      await prefs.remove(_appLocaleCodeKey);
      appLocaleOverride.value = null;
      return;
    }
    final String code = locale.languageCode;
    if (code != 'en' && code != 'mk' && code != 'sq') {
      return;
    }
    await prefs.setString(_appLocaleCodeKey, code);
    appLocaleOverride.value = Locale(code);
  }

  void reset() {
    EngagementOutboxCoordinator.dispose();
    EventOfflineWorkCoordinator.instance.dispose();
    CheckInSyncService.dispose();
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
    _eventAnalyticsRepository = null;
    _eventChatRepository = null;
    _initialized = false;
    appLocaleOverride.value = null;
  }
}
