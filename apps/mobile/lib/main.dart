import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:chisto_infrastructure/core/auth/auth_session_scope.dart';
import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/bootstrap/cold_start_coordinator.dart';
import 'package:chisto_infrastructure/core/bootstrap/push_setup_coordinator.dart';
import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/deep_links/deep_link_router.dart';
import 'package:chisto_infrastructure/core/deep_links/share_token_from_route.dart';
import 'package:chisto_infrastructure/core/diagnostics/global_error_handlers.dart';
import 'package:chisto_infrastructure/core/image/image_cache_governor.dart';
import 'package:chisto_infrastructure/core/l10n/app_locale_resolution.dart';
import 'package:chisto_infrastructure/core/lifecycle/map_realtime_lifecycle.dart';
import 'package:chisto_infrastructure/core/lifecycle/notifications_inbox_lifecycle.dart';
import 'package:chisto_infrastructure/core/lifecycle/reports_realtime_lifecycle.dart';
import 'package:chisto_infrastructure/core/lifecycle/session_resume_refresh_lifecycle.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/navigation/app_go_router.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigator_key.dart';
import 'package:chisto_infrastructure/core/observability/chisto_sentry.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/providers/home_providers.dart';
import 'package:chisto_infrastructure/core/providers/notifications_providers.dart';
import 'package:chisto_infrastructure/core/providers/refresh_signals_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_mobile/core/background/chisto_workmanager_dispatcher.dart';
import 'package:chisto_mobile/firebase_options.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_notifications/src/data/application_notification_badge_sync.dart';
import 'package:feature_notifications/src/data/firebase_background_message_handler.dart';
import 'package:feature_notifications/src/data/notification_inbox_refresh.dart';
import 'package:feature_notifications/src/data/notification_open_router.dart';
import 'package:feature_notifications/src/data/push_notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show
        TargetPlatform,
        defaultTargetPlatform,
        kDebugMode,
        kIsWeb,
        kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:workmanager/workmanager.dart';

Future<void> main() async {
  final String sentryDsn = const String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  ).trim();
  final bool sentryEnabled = sentryDsn.isNotEmpty;
  final Completer<void> done = Completer<void>();

  // Single zone for [ensureInitialized], [runApp], and uncaught async errors.
  runZonedGuarded<void>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      installGlobalErrorHandlers(useSentry: sentryEnabled);
      try {
        if (sentryEnabled) {
          final PackageInfo packageInfo = await PackageInfo.fromPlatform();
          const String sentryEnvironment = String.fromEnvironment(
            'SENTRY_ENVIRONMENT',
            defaultValue: '',
          );
          final String env = sentryEnvironment.isNotEmpty
              ? sentryEnvironment
              : (const String.fromEnvironment('ENV', defaultValue: 'dev') ==
                        'prod'
                    ? 'production'
                    : 'beta');
          await SentryFlutter.init((options) {
            options.dsn = sentryDsn;
            options.sendDefaultPii = false;
            options.tracesSampleRate = 0.05;
            options.environment = env;
            options.release =
                'chisto_mobile@${packageInfo.version}+${packageInfo.buildNumber}';
            options.beforeSend = chistoSentryBeforeSend;
          }, appRunner: _bootstrapAndRun);
        } else {
          await _bootstrapAndRun();
        }
      } finally {
        if (!done.isCompleted) done.complete();
      }
    },
    (Object error, StackTrace stack) {
      AppLog.error('Uncaught zone error', error: error, stackTrace: stack);
      if (sentryEnabled) {
        unawaited(Sentry.captureException(error, stackTrace: stack));
      }
    },
  );
  await done.future;
}

Future<void> _bootstrapAndRun() async {
  if (kReleaseMode) {
    final AppConfig config = AppConfig.fromEnvironment();
    if (!config.isProd) {
      throw StateError(
        'Release builds must pass --dart-define=ENV=prod (got ${config.environment.name})',
      );
    }
    AppConfig.assertReleaseTransportSecurity(config.apiBaseUrl);
  }

  // Use FFI sqflite only on desktop; iOS/Android use the native implementation (avoids global factory warning on mobile).
  if (!kIsWeb) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        break;
    }
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (Firebase.apps.isNotEmpty) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
  } on Object catch (e, st) {
    AppLog.warn(
      '[Firebase] Init error (run flutterfire configure if push is required): $e',
      error: e,
      stackTrace: st,
    );
  }
  await AppBootstrap.instance.initialize();
  setRootProviderContainer(AppBootstrap.instance.providerContainer);

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  runApp(
    UncontrolledProviderScope(
      container: AppBootstrap.instance.providerContainer,
      child: const ChistoApp(),
    ),
  );
}

bool _workmanagerRegistrationAttempted = false;

/// Initializes Workmanager for report outbox background drain (does not block cold start).
Future<void> registerChistoWorkmanagerIfNeeded() async {
  if (_workmanagerRegistrationAttempted) {
    return;
  }
  _workmanagerRegistrationAttempted = true;
  final bool mobileForWorkmanager =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  if (!mobileForWorkmanager) {
    return;
  }
  try {
    await Workmanager().initialize(chistoWorkmanagerCallbackDispatcher);
  } on MissingPluginException catch (e) {
    AppLog.verbose(
      '[Workmanager] Skipped (${defaultTargetPlatform.name}): '
      'no native implementation ($e).',
    );
  } on Object catch (e, st) {
    AppLog.warn('[Workmanager] init failed: $e', error: e, stackTrace: st);
  }
}

class ChistoApp extends StatefulWidget {
  const ChistoApp({super.key});

  @override
  State<ChistoApp> createState() => _ChistoAppState();
}

class _ChistoAppState extends State<ChistoApp> {
  late final GoRouter _router;
  final AppLinks _appLinks = AppLinks();
  final ReportsRealtimeLifecycle _reportsRealtimeLifecycle =
      ReportsRealtimeLifecycle();
  final MapRealtimeLifecycle _mapRealtimeLifecycle = MapRealtimeLifecycle();
  final NotificationsInboxLifecycle _notificationsInboxLifecycle =
      NotificationsInboxLifecycle();
  final SessionResumeRefreshLifecycle _sessionResumeRefreshLifecycle =
      SessionResumeRefreshLifecycle();
  StreamSubscription<RemoteMessage>? _tapSubscription;
  StreamSubscription<Map<String, dynamic>>? _localNotificationTapSubscription;
  StreamSubscription<Uri>? _deepLinkSubscription;
  PushSetupCoordinator? _pushSetupCoordinator;
  RemoteMessage? _pendingPushOpen;
  int _pendingPushOpenAttempts = 0;
  static const int _maxPendingPushOpenAttempts = 120;
  String? _lastConsumedPushMessageId;
  DateTime? _lastConsumedPushAt;

  @override
  void initState() {
    super.initState();
    _router = buildAppGoRouter();
    ImageCacheGovernor.instance.install();
    _reportsRealtimeLifecycle.register();
    _mapRealtimeLifecycle.register();
    _notificationsInboxLifecycle.register();
    _sessionResumeRefreshLifecycle.register();
    final PushNotificationService push = readRoot(
      pushNotificationServiceProvider,
    );
    _tapSubscription = push.notificationTaps.listen(_onNotificationTap);
    _localNotificationTapSubscription = push.localNotificationTaps.listen(
      _onLocalNotificationTap,
    );
    // iOS (FlutterImplicitEngineDelegate): native plugins register in
    // `didInitializeImplicitFlutterEngine`, which can run after the first
    // frame. Subscribing to `app_links` in initState races and causes
    // MissingPluginException on `com.llfbandit.app_links/events`.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      installApplicationBadgeSync();
      unawaited(_initDeepLinks());
      _pushSetupCoordinator = PushSetupCoordinator(
        pushService: readRoot(pushNotificationServiceProvider),
        preferences: readRoot(preferencesProvider),
        navigatorKey: appRootNavigatorKey,
        isMounted: () => mounted,
        onForegroundMessage: (RemoteMessage message) {
          final Map<String, dynamic> data = message.data;
          bumpNotificationsInboxRefreshTick(data);
          if (data['type'] == 'CLEANUP_EVENT' && data['kind'] == 'published') {
            bumpEventsFeedRefresh();
          }
        },
      );
      unawaited(_pushSetupCoordinator!.bootstrap());
      unawaited(_pushSetupCoordinator!.offerPermissionWithRetries());
      unawaited(registerChistoWorkmanagerIfNeeded());
    });
  }

  Future<void> _initDeepLinks() async {
    try {
      final Uri? initial = await _appLinks.getInitialLink();
      if (initial != null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _dispatchDeepLink(initial),
        );
      }
    } on MissingPluginException catch (e) {
      AppLog.verbose(
        '[DeepLink] app_links native side not ready or missing (try full rebuild): $e',
      );
      return;
    } catch (e) {
      AppLog.warn('[DeepLink] getInitialLink failed: $e', error: e);
    }
    try {
      _deepLinkSubscription = _appLinks.uriLinkStream.listen(
        _dispatchDeepLink,
        onError: (Object e) =>
            AppLog.warn('[DeepLink] stream error: $e', error: e),
      );
    } on MissingPluginException catch (e) {
      AppLog.verbose(
        '[DeepLink] app_links stream unavailable (try full rebuild): $e',
      );
    }
  }

  void _dispatchDeepLink(Uri uri) {
    final ColdStartCoordinator coordinator = ColdStartCoordinator.instance;
    final BuildContext? ctx =
        _router.routerDelegate.navigatorKey.currentContext;
    if (ctx == null) {
      coordinator.queueDeepLink(uri);
      return;
    }
    if (!coordinator.isReadyForLaunch) {
      coordinator.queueDeepLink(uri);
      return;
    }
    if (ctx.mounted && coordinator.peekPendingIntent() != null) {
      coordinator.queueDeepLink(uri);
      coordinator.tryApply(router: _router, context: ctx);
      return;
    }
    final DeepLinkRoute? parsed = DeepLinkRouter.parse(uri);
    final bool handled = DeepLinkRouter.handleUri(
      _router,
      uri,
      isAuthenticated: readRoot(authStateProvider).isAuthenticated,
    );
    if (handled && parsed != null) {
      unawaited(_trackShareOpenFromDeepLink(parsed));
    }
    if (!handled && kDebugMode) {
      AppLog.verbose('[DeepLink] Unhandled URI: $uri');
    }
  }

  Future<void> _trackShareOpenFromDeepLink(DeepLinkRoute? route) async {
    final String? token = shareTokenFromDeepLinkRoute(route);
    if (token == null || token.isEmpty) {
      return;
    }
    try {
      await readRoot(
        sitesRepositoryProvider,
      ).ingestSiteShareOpen(token: token, eventType: 'OPEN', source: 'APP');
    } on Object catch (e, st) {
      AppLog.warn(
        '[DeepLink] Share open tracking failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  void dispose() {
    _reportsRealtimeLifecycle.unregister();
    _mapRealtimeLifecycle.unregister();
    _notificationsInboxLifecycle.unregister();
    _sessionResumeRefreshLifecycle.unregister();
    ImageCacheGovernor.instance.uninstall();
    _deepLinkSubscription?.cancel();
    _pushSetupCoordinator?.dispose();
    _pushSetupCoordinator = null;
    _localNotificationTapSubscription?.cancel();
    _tapSubscription?.cancel();
    super.dispose();
  }

  void _onLocalNotificationTap(Map<String, dynamic> data) {
    bumpNotificationsInboxRefreshTick(data);
    _pendingPushOpen = null;
    _pendingPushOpenAttempts = 0;
    final BuildContext? ctx =
        _router.routerDelegate.navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      NotificationOpenRouter.handleOpenFromData(ctx, data);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final BuildContext? lateCtx =
          _router.routerDelegate.navigatorKey.currentContext;
      if (lateCtx != null && lateCtx.mounted) {
        NotificationOpenRouter.handleOpenFromData(lateCtx, data);
      }
    });
  }

  void _onNotificationTap(RemoteMessage message) {
    bumpNotificationsInboxRefreshTick(message.data);
    final String? id = message.messageId;
    if (id != null &&
        id.isNotEmpty &&
        id == _lastConsumedPushMessageId &&
        _lastConsumedPushAt != null &&
        DateTime.now().difference(_lastConsumedPushAt!) <
            const Duration(seconds: 3)) {
      return;
    }
    _pendingPushOpen = message;
    _pendingPushOpenAttempts = 0;
    _tryConsumePendingPushOpen();
  }

  void _tryConsumePendingPushOpen() {
    final RemoteMessage? message = _pendingPushOpen;
    if (message == null) {
      return;
    }
    final BuildContext? ctx =
        _router.routerDelegate.navigatorKey.currentContext;
    if (ctx == null) {
      if (_pendingPushOpenAttempts >= _maxPendingPushOpenAttempts) {
        AppLog.verbose('[Push] Open dropped: navigator context not ready');
        _pendingPushOpen = null;
        _pendingPushOpenAttempts = 0;
        return;
      }
      _pendingPushOpenAttempts += 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tryConsumePendingPushOpen();
        }
      });
      return;
    }
    _pendingPushOpen = null;
    _pendingPushOpenAttempts = 0;
    NotificationOpenRouter.handleOpen(ctx, message);
    final String? mid = message.messageId;
    if (mid != null && mid.isNotEmpty) {
      _lastConsumedPushMessageId = mid;
      _lastConsumedPushAt = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, _) {
        final Locale? override = ref.watch(appLocaleOverrideProvider);
        return AuthSessionScope(
          child: MaterialApp.router(
            builder: (BuildContext context, Widget? child) {
              final TextScaler scaler = MediaQuery.textScalerOf(
                context,
              ).clamp(maxScaleFactor: 1.6);
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: scaler),
                child: child ?? const SizedBox.shrink(),
              );
            },
            routerConfig: _router,
            onGenerateTitle: (BuildContext context) =>
                AppLocalizations.of(context)!.authOnboardingBrandName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            locale: override,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            localeListResolutionCallback:
                (List<Locale>? locales, Iterable<Locale> _) {
                  return resolveAppLocale(
                    override: override,
                    platformLocales: locales ?? <Locale>[],
                  );
                },
          ),
        );
      },
    );
  }
}
