import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/bootstrap/cold_start_coordinator.dart';
import 'package:chisto_infrastructure/core/cache/report_images_cache.dart';
import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/l10n/app_locale_resolution.dart';
import 'package:chisto_infrastructure/core/location/geolocator_location_service.dart';
import 'package:chisto_infrastructure/core/location/location_service.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/storage/secure_token_storage.dart';
import 'package:chisto_infrastructure/core/time/server_clock.dart';
import 'package:feature_auth/src/data/api_auth_repository.dart';
import 'package:feature_auth/src/domain/repositories/auth_repository.dart';
import 'package:feature_events/src/data/api_check_in_repository.dart';
import 'package:feature_events/src/data/api_event_analytics_repository.dart';
import 'package:feature_events/src/data/api_events_repository.dart';
import 'package:feature_events/src/data/chat/api_event_chat_repository.dart';
import 'package:feature_events/src/data/chat/event_chat_repository.dart';
import 'package:feature_events/src/data/check_in_sync_service.dart';
import 'package:feature_events/src/data/event_offline_work_coordinator.dart';
import 'package:feature_events/src/domain/repositories/check_in_repository.dart';
import 'package:feature_events/src/domain/repositories/events_repository.dart';
import 'package:feature_home/src/data/api_sites_repository.dart';
import 'package:feature_home/src/data/engagement_outbox_coordinator.dart';
import 'package:feature_home/src/data/map_realtime/map_realtime_service.dart';
import 'package:feature_home/src/domain/repositories/sites_repository.dart';
import 'package:feature_notifications/src/data/api_notifications_repository.dart';
import 'package:feature_notifications/src/data/notifications_inbox_coordinator.dart';
import 'package:feature_notifications/src/data/notifications_realtime_service.dart';
import 'package:feature_notifications/src/data/push_notification_service.dart';
import 'package:feature_notifications/src/domain/repositories/notifications_repository.dart';
import 'package:feature_onboarding/src/data/shared_prefs_feature_guide_repository.dart';
import 'package:feature_onboarding/src/domain/feature_guide_repository.dart';
import 'package:feature_profile/src/data/api_profile_repository.dart';
import 'package:feature_profile/src/data/riverpod_profile_avatar_sync.dart';
import 'package:feature_profile/src/domain/repositories/profile_repository.dart';
import 'package:feature_reports/src/application/report_wizard_submit_port.dart';
import 'package:feature_reports/src/application/reports_list_session.dart';
import 'package:feature_reports/src/data/api_reports_repository.dart';
import 'package:feature_reports/src/data/outbox/background/background_submit_scheduler.dart';
import 'package:feature_reports/src/data/outbox/background/platform_background_submit_scheduler.dart';
import 'package:feature_reports/src/data/outbox/report_draft_photo_store.dart';
import 'package:feature_reports/src/data/outbox/report_draft_repository.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_coordinator.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_migration_from_sp.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_repository.dart';
import 'package:feature_reports/src/data/reports_realtime/reports_realtime_service.dart';
import 'package:feature_reports/src/domain/repositories/reports_api_repository.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppBootstrap {
  AppBootstrap._();

  static final AppBootstrap instance = AppBootstrap._();

  static const String _appLocaleCodeKey = 'app_locale_code';

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
  ReportOutboxRepository? _reportOutboxRepository;
  ReportDraftPhotoStore? _reportDraftPhotoStore;
  ReportDraftRepository? _reportDraftRepository;
  ReportOutboxCoordinator? _reportOutboxCoordinator;
  ReportWizardSubmitPort? _reportWizardSubmitPort;
  ReportsRealtimeService? _reportsRealtimeService;
  SitesRepository? _sitesRepository;
  LocationService? _locationService;
  MapRealtimeService? _mapRealtimeService;
  NotificationsRepository? _notificationsRepository;
  NotificationsInboxCoordinator? _notificationsInboxCoordinator;
  NotificationsRealtimeService? _notificationsRealtimeService;
  PushNotificationService? _pushNotificationService;
  ApiEventAnalyticsRepository? _eventAnalyticsRepository;
  EventChatRepository? _eventChatRepository;
  FeatureGuideRepository? _featureGuideRepository;

  /// Active "My reports" list session for optimistic inserts after submit.
  final ReportsListSession reportsListSession = ReportsListSession();

  /// Set by [AuthSessionScope] for global session-loss navigation (legacy).
  VoidCallback? onAuthUnauthorized;
  VoidCallback? onExplicitSignOut;

  AppConfig get config => _config!;
  AuthState? get authStateOrNull => _authState;
  AuthState get authState => _authState!;
  SecureTokenStorage get tokenStorage => _tokenStorage!;
  SharedPreferences get preferences => _preferences!;
  ApiClient get apiClient => _apiClient!;
  AuthRepository get authRepository => _authRepository!;

  /// Replaces the live auth repository in widget/unit tests (e.g. terms dialog).
  @visibleForTesting
  void overrideAuthRepositoryForTests(AuthRepository repository) {
    _authRepository = repository;
    _authRepositoryForUnauthorized = repository;
  }

  EventsRepository get eventsRepository => _eventsRepository!;
  CheckInRepository get checkInRepository => _checkInRepository!;
  ProfileRepository get profileRepository => _profileRepository!;
  ReportsApiRepository get reportsApiRepository => _reportsApiRepository!;
  ReportOutboxRepository get reportOutboxRepository => _reportOutboxRepository!;
  ReportDraftPhotoStore get reportDraftPhotoStore => _reportDraftPhotoStore!;
  ReportDraftRepository get reportDraftRepository => _reportDraftRepository!;
  ReportOutboxCoordinator get reportOutboxCoordinator =>
      _reportOutboxCoordinator!;
  ReportWizardSubmitPort get reportWizardSubmitPort => _reportWizardSubmitPort!;
  ReportsRealtimeService get reportsRealtimeService => _reportsRealtimeService!;
  SitesRepository get sitesRepository => _sitesRepository!;
  LocationService get locationService => _locationService!;
  MapRealtimeService get mapRealtimeService => _mapRealtimeService!;
  NotificationsRepository get notificationsRepository =>
      _notificationsRepository!;
  NotificationsInboxCoordinator get notificationsInboxCoordinator =>
      _notificationsInboxCoordinator!;
  NotificationsRealtimeService get notificationsRealtimeService =>
      _notificationsRealtimeService!;
  PushNotificationService get pushNotificationService =>
      _pushNotificationService!;

  ApiEventAnalyticsRepository get eventAnalyticsRepository =>
      _eventAnalyticsRepository!;

  EventChatRepository get eventChatRepository => _eventChatRepository!;

  FeatureGuideRepository get featureGuideRepository => _featureGuideRepository!;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// While clearing session, ignore 401 callbacks from best-effort unregister.
  bool suppressUnauthorizedCallback = false;

  /// Set when [ApiAuthRepository.restoreSession] rejects stale tokens; consumed by
  /// [AuthSessionScope] to avoid a false "session expired" snack on sign-in.
  bool suppressSessionExpiredMessage = false;

  DateTime? _suppressSessionExpiredUntil;

  /// Arms a short window where session-loss snack is suppressed (cold restore race).
  void armSuppressSessionExpiredWindow([
    Duration duration = const Duration(milliseconds: 500),
  ]) {
    suppressSessionExpiredMessage = true;
    _suppressSessionExpiredUntil = DateTime.now().add(duration);
  }

  /// Returns true once and clears [suppressSessionExpiredMessage].
  bool consumeSuppressSessionExpiredMessage() {
    if (!suppressSessionExpiredMessage) {
      return false;
    }
    suppressSessionExpiredMessage = false;
    return true;
  }

  bool shouldSuppressSessionExpiredMessage() {
    if (consumeSuppressSessionExpiredMessage()) {
      return true;
    }
    final DateTime? until = _suppressSessionExpiredUntil;
    if (until != null && DateTime.now().isBefore(until)) {
      return true;
    }
    _suppressSessionExpiredUntil = null;
    return false;
  }

  /// Starts inbox realtime when the session is validated (login or `/auth/me`).
  void startNotificationsRealtimeIfAuthenticated() {
    if (_authState?.isAuthenticated ?? false) {
      notificationsRealtimeService.start();
    }
  }

  /// Root Riverpod container (created in [initialize]). Used by non-widget code
  /// (e.g. auth) to sync profile avatar preview with [profileAvatarNotifierProvider].
  ProviderContainer? _providerContainer;

  /// Non-null after [initialize] completes.
  ProviderContainer get providerContainer {
    final ProviderContainer? c = _providerContainer;
    if (c == null) {
      throw StateError('AppBootstrap.providerContainer before initialize');
    }
    return c;
  }

  Future<void> initialize({AppConfig? config}) async {
    if (_initialized) return;

    _config = config ?? AppConfig.fromEnvironment();
    _authState = AuthState();
    _tokenStorage = SecureTokenStorage();
    ApiClientHooks.recordServerDateHeader =
        ServerClock.instance.recordDateHeader;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _preferences = prefs;
    _providerContainer = ProviderContainer(
      overrides: <Override>[appBootstrapProvider.overrideWithValue(this)],
    );

    _apiClient = ApiClient(
      config: _config!,
      accessToken: () => _authState!.accessToken,
      onUnauthorized: () {
        if (suppressUnauthorizedCallback) {
          return;
        }
        final AuthRepository? repo = _authRepositoryForUnauthorized;
        if (repo != null) {
          unawaited(repo.invalidateLocalSession());
        } else {
          _authState!.setUnauthenticated();
        }
        onAuthUnauthorized?.call();
      },
      acceptLanguageHeader: () {
        final Locale effective = resolveAppLocale(
          override: _providerContainer?.read(appLocaleOverrideProvider),
          platformLocales: PlatformDispatcher.instance.locales,
        );
        return acceptLanguageFromLocale(effective);
      },
      deviceIdHeader: () => _tokenStorage!.deviceId,
    );

    _notificationsRepository = ApiNotificationsRepository(client: _apiClient!);
    _notificationsInboxCoordinator = NotificationsInboxCoordinator(
      repository: _notificationsRepository!,
    );
    _notificationsRealtimeService = NotificationsRealtimeService(
      config: _config!,
      authState: _authState!,
      sessionRefresh: () => _apiClient!.refreshSessionQueued(),
      onAuthRejected: () {
        if (suppressUnauthorizedCallback) {
          return;
        }
        _apiClient!.notifySessionAuthRejected();
      },
    );
    _pushNotificationService = PushNotificationService(
      repository: _notificationsRepository!,
      isAuthenticated: () => _authState?.isAuthenticated ?? false,
    );

    _authRepository = ApiAuthRepository(
      client: _apiClient!,
      authState: _authState!,
      tokenStorage: _tokenStorage!,
      preferences: prefs,
      pushService: _pushNotificationService,
      avatarSync: RiverpodProfileAvatarSync(_providerContainer!),
    );
    _authRepositoryForUnauthorized = _authRepository;

    _featureGuideRepository = SharedPrefsFeatureGuideRepository(
      prefs,
      currentUserId: () {
        final String? id = _authState!.userId?.trim();
        if (id != null && id.isNotEmpty) {
          return id;
        }
        final String? phone = _authState!.phoneNumber?.trim();
        if (phone != null && phone.isNotEmpty) {
          return phone;
        }
        return null;
      },
    );

    _apiClient!.refreshSession = () => _authRepository!.refreshSession();

    final ApiEventsRepository eventsRepo = ApiEventsRepository(
      client: _apiClient!,
    );
    _eventsRepository = eventsRepo;
    _checkInRepository = ApiCheckInRepository(
      client: _apiClient!,
      eventsRepository: eventsRepo,
    );
    _profileRepository = ApiProfileRepository(client: _apiClient!);
    _reportsApiRepository = ApiReportsRepository(client: _apiClient!);
    _reportOutboxRepository = await SqfliteReportOutboxRepository.open();
    _reportDraftPhotoStore = ReportDraftPhotoStore();
    _reportDraftRepository = ReportDraftRepository(
      outbox: _reportOutboxRepository!,
      photoStore: _reportDraftPhotoStore!,
    );
    // One-shot SharedPreferences → SQLite migration; retain until analytics
    // confirms the entire fleet has migrated (see plan Phase 7.1).
    await ReportOutboxMigrationFromSp.runOnce(_reportOutboxRepository!);
    unawaited(_reportDraftRepository!.hydrate());
    _reportOutboxCoordinator = ReportOutboxCoordinator(
      repository: _reportOutboxRepository!,
      reportsApi: _reportsApiRepository!,
      backgroundSubmitScheduler: _reportBackgroundSubmitScheduler(),
    );
    unawaited(_reportOutboxCoordinator!.start());
    _reportWizardSubmitPort = ReportWizardSubmitPortImpl(
      _reportOutboxCoordinator!,
    );
    _reportsRealtimeService = ReportsRealtimeService(
      config: _config!,
      authState: _authState!,
      sessionRefresh: () => _apiClient!.refreshSessionQueued(),
      onAuthRejected: () {
        if (suppressUnauthorizedCallback) {
          return;
        }
        _apiClient!.notifySessionAuthRejected();
      },
    );
    unawaited(_reportsRealtimeService!.start());
    _mapRealtimeService = MapRealtimeService(
      config: _config!,
      authState: _authState!,
      sessionRefresh: () => _apiClient!.refreshSessionQueued(),
      onAuthRejected: () {
        if (suppressUnauthorizedCallback) {
          return;
        }
        _apiClient!.notifySessionAuthRejected();
      },
    );
    _locationService = GeolocatorLocationService();
    _sitesRepository = ApiSitesRepository(
      client: _apiClient!,
      authState: _authState,
    );
    unawaited(
      EngagementOutboxCoordinator.start(
        sitesRepository: _sitesRepository!,
        authState: _authState!,
      ),
    );
    _eventAnalyticsRepository = ApiEventAnalyticsRepository(
      client: _apiClient!,
    );
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

    unawaited(maybeEvictReportImagesDiskCacheIfHeavy());

    _initialized = true;
    ColdStartCoordinator.instance.markBootstrapReady();
  }

  void _loadStoredAppLocale(SharedPreferences prefs) {
    final String? code = prefs.getString(_appLocaleCodeKey);
    final ProviderContainer? container = _providerContainer;
    if (container == null) return;
    if (code == 'en') {
      container.read(appLocaleOverrideProvider.notifier).state = const Locale(
        'en',
      );
    } else if (code == 'mk') {
      container.read(appLocaleOverrideProvider.notifier).state = const Locale(
        'mk',
      );
    } else if (code == 'sq') {
      container.read(appLocaleOverrideProvider.notifier).state = const Locale(
        'sq',
      );
    } else {
      container.read(appLocaleOverrideProvider.notifier).state = null;
    }
  }

  /// Persists choice. Pass [null] to use device language.
  Future<void> setAppLocale(Locale? locale) async {
    final SharedPreferences prefs = _preferences!;
    final ProviderContainer container = providerContainer;
    if (locale == null) {
      await prefs.remove(_appLocaleCodeKey);
      container.read(appLocaleOverrideProvider.notifier).state = null;
      return;
    }
    final String code = locale.languageCode;
    if (code != 'en' && code != 'mk' && code != 'sq') {
      return;
    }
    await prefs.setString(_appLocaleCodeKey, code);
    container.read(appLocaleOverrideProvider.notifier).state = Locale(code);
  }

  Future<void> reset() async {
    _providerContainer?.dispose();
    _providerContainer = null;
    EngagementOutboxCoordinator.dispose();
    EventOfflineWorkCoordinator.instance.dispose();
    CheckInSyncService.dispose();
    final ReportOutboxCoordinator? outbox = _reportOutboxCoordinator;
    _reportOutboxCoordinator = null;
    if (outbox != null) {
      await outbox.dispose();
    }
    _reportWizardSubmitPort = null;
    _reportDraftRepository = null;
    _reportDraftPhotoStore = null;
    _reportOutboxRepository = null;
    _reportsRealtimeService?.dispose();
    _mapRealtimeService?.dispose();
    _notificationsRealtimeService?.dispose();
    _notificationsRealtimeService = null;
    _pushNotificationService?.dispose();
    _config = null;
    _authState = null;
    _tokenStorage = null;
    _preferences = null;
    final ApiClient? clientToClose = _apiClient;
    _apiClient = null;
    clientToClose?.dispose();
    _authRepository = null;
    _authRepositoryForUnauthorized = null;
    _eventsRepository = null;
    _checkInRepository = null;
    _profileRepository = null;
    _reportsApiRepository = null;
    _reportsRealtimeService = null;
    _mapRealtimeService = null;
    _locationService = null;
    _sitesRepository = null;
    _notificationsRepository = null;
    _notificationsInboxCoordinator = null;
    _pushNotificationService = null;
    _eventAnalyticsRepository = null;
    _eventChatRepository = null;
    _featureGuideRepository = null;
    _initialized = false;
  }

  BackgroundSubmitScheduler _reportBackgroundSubmitScheduler() {
    if (kIsWeb) {
      return InProcessBackgroundSubmitScheduler();
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return PlatformBackgroundSubmitScheduler();
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return InProcessBackgroundSubmitScheduler();
    }
  }
}
