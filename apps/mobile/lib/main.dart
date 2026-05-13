import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'package:chisto_mobile/core/app_theme.dart';
import 'package:chisto_mobile/core/logging/app_log.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/image/image_cache_governor.dart';
import 'package:chisto_mobile/core/lifecycle/map_realtime_lifecycle.dart';
import 'package:chisto_mobile/core/lifecycle/reports_realtime_lifecycle.dart';
import 'package:chisto_mobile/core/l10n/app_locale_resolution.dart';
import 'package:chisto_mobile/core/deep_links/deep_link_router.dart';
import 'package:chisto_mobile/core/deep_links/share_token_from_route.dart';
import 'package:chisto_mobile/core/navigation/app_navigator_key.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/features/home/data/offline_regions/offline_refresh_dispatcher.dart';
import 'package:chisto_mobile/features/notifications/data/notification_open_router.dart';
import 'package:chisto_mobile/features/notifications/data/push_notification_service.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final String sentryDsn =
      const String.fromEnvironment('SENTRY_DSN', defaultValue: '').trim();
  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.sendDefaultPii = false;
        options.tracesSampleRate = 0.05;
      },
      appRunner: _runChistoMobile,
    );
  } else {
    await _runChistoMobile();
  }
}

Future<void> _runChistoMobile() async {
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
  await Hive.initFlutter();
  try {
    await Firebase.initializeApp();
  } on Object catch (e, st) {
    AppLog.warn('[Firebase] Init error (expected in dev/simulator): $e', error: e, stackTrace: st);
  }
  await ServiceLocator.instance.initialize();

  final bool mobileForWorkmanager =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  if (mobileForWorkmanager) {
    try {
      await Workmanager().initialize(
        offlineRegionsCallbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      await Workmanager().registerPeriodicTask(
        'offline-regions-refresh',
        OfflineRefreshDispatcher.taskName,
        frequency: const Duration(hours: 24),
        constraints: Constraints(
          networkType: NetworkType.unmetered,
        ),
      );
    } on MissingPluginException catch (e) {
      // Common on iOS Simulator or before native Gradle/Info.plist BG setup linked.
      AppLog.verbose(
        '[Workmanager] Skipped (${defaultTargetPlatform.name}): '
        'no native implementation ($e). Periodic offline refresh unavailable; '
        'in-app download still works.',
      );
    } catch (e, st) {
      AppLog.warn('[Workmanager] offline regions refresh init failed: $e', error: e, stackTrace: st);
    }
  }
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  runApp(
    UncontrolledProviderScope(
      container: ServiceLocator.instance.providerContainer,
      child: const ChistoApp(),
    ),
  );
}

class ChistoApp extends StatefulWidget {
  const ChistoApp({super.key});

  @override
  State<ChistoApp> createState() => _ChistoAppState();
}

class _ChistoAppState extends State<ChistoApp> {
  final GlobalKey<NavigatorState> _navigatorKey = appRootNavigatorKey;
  final AppLinks _appLinks = AppLinks();
  final ReportsRealtimeLifecycle _reportsRealtimeLifecycle =
      ReportsRealtimeLifecycle();
  final MapRealtimeLifecycle _mapRealtimeLifecycle = MapRealtimeLifecycle();
  StreamSubscription<RemoteMessage>? _tapSubscription;
  StreamSubscription<RemoteMessage>? _foregroundPushSubscription;
  StreamSubscription<Uri>? _deepLinkSubscription;
  RemoteMessage? _pendingPushOpen;
  int _pendingPushOpenAttempts = 0;
  static const int _maxPendingPushOpenAttempts = 120;
  String? _lastConsumedPushMessageId;
  DateTime? _lastConsumedPushAt;

  @override
  void initState() {
    super.initState();
    ImageCacheGovernor.instance.install();
    _reportsRealtimeLifecycle.register();
    _mapRealtimeLifecycle.register();
    final PushNotificationService push =
        ServiceLocator.instance.pushNotificationService;
    _tapSubscription = push.notificationTaps.listen(_onNotificationTap);
    // iOS (FlutterImplicitEngineDelegate): native plugins register in
    // `didInitializeImplicitFlutterEngine`, which can run after the first
    // frame. Subscribing to `app_links` in initState races and causes
    // MissingPluginException on `com.llfbandit.app_links/events`.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initDeepLinks());
      unawaited(_bootstrapPush());
      unawaited(_maybeOfferPushPermissionRationale());
    });
  }

  Future<void> _bootstrapPush() async {
    final PushNotificationService push =
        ServiceLocator.instance.pushNotificationService;
    await push.initialize(
      appLanguageOverride: ServiceLocator.instance.appLocaleOverride.value,
    );
    if (!mounted) return;
    _foregroundPushSubscription = push.foregroundMessages.listen(
      (RemoteMessage message) {
        final Map<String, dynamic> data = message.data;
        if (data['type'] == 'CLEANUP_EVENT' && data['kind'] == 'published') {
          ServiceLocator.instance.eventsFeedRemoteRefreshTick.value++;
        }
      },
    );
  }

  Future<void> _maybeOfferPushPermissionRationale() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final PushNotificationService push =
        ServiceLocator.instance.pushNotificationService;
    if (!push.isFirebaseReady) return;
    final SharedPreferences prefs = ServiceLocator.instance.preferences;
    if (prefs.getBool(kPushOsPermissionFlowCompletedKey) == true) return;
    final BuildContext? ctx = _navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    final AppLocalizations l10n = AppLocalizations.of(ctx)!;
    final bool? accepted = await showDialog<bool>(
      context: ctx,
      barrierDismissible: true,
      builder: (BuildContext c) => AlertDialog(
        title: Text(l10n.pushPermissionRationaleTitle),
        content: Text(l10n.pushPermissionRationaleBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: Text(l10n.pushPermissionRationaleNotNow),
          ),
          FilledButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: Text(l10n.pushPermissionRationaleAllow),
          ),
        ],
      ),
    );
    await prefs.setBool(kPushOsPermissionFlowCompletedKey, true);
    if (!mounted) return;
    if (accepted == true) {
      await push.requestSystemNotificationPermission();
    }
  }

  Future<void> _initDeepLinks() async {
    try {
      final Uri? initial = await _appLinks.getInitialLink();
      if (initial != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _dispatchDeepLink(initial));
      }
    } on MissingPluginException catch (e) {
      AppLog.verbose('[DeepLink] app_links native side not ready or missing (try full rebuild): $e');
      return;
    } catch (e) {
      AppLog.warn('[DeepLink] getInitialLink failed: $e', error: e);
    }
    try {
      _deepLinkSubscription = _appLinks.uriLinkStream.listen(
        _dispatchDeepLink,
        onError: (Object e) => AppLog.warn('[DeepLink] stream error: $e', error: e),
      );
    } on MissingPluginException catch (e) {
      AppLog.verbose('[DeepLink] app_links stream unavailable (try full rebuild): $e');
    }
  }

  void _dispatchDeepLink(Uri uri) {
    final NavigatorState? nav = _navigatorKey.currentState;
    if (nav == null) {
      return;
    }
    final DeepLinkRoute? parsed = DeepLinkRouter.parse(uri);
    final bool handled = DeepLinkRouter.handleUri(
      nav,
      uri,
      isAuthenticated: ServiceLocator.instance.authState.isAuthenticated,
    );
    if (handled) {
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
      await ServiceLocator.instance.sitesRepository.ingestSiteShareOpen(
        token: token,
        eventType: 'OPEN',
        source: 'APP',
      );
    } catch (_) {
      // Deliberate: attribution tracking must never block deep-link routing.
    }
  }

  @override
  void dispose() {
    _reportsRealtimeLifecycle.unregister();
    _mapRealtimeLifecycle.unregister();
    ImageCacheGovernor.instance.uninstall();
    _deepLinkSubscription?.cancel();
    _foregroundPushSubscription?.cancel();
    _tapSubscription?.cancel();
    super.dispose();
  }

  void _onNotificationTap(RemoteMessage message) {
    final String? id = message.messageId;
    if (id != null &&
        id.isNotEmpty &&
        id == _lastConsumedPushMessageId &&
        _lastConsumedPushAt != null &&
        DateTime.now().difference(_lastConsumedPushAt!) < const Duration(seconds: 3)) {
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
    final BuildContext? ctx = _navigatorKey.currentContext;
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
    return ValueListenableBuilder<Locale?>(
      valueListenable: ServiceLocator.instance.appLocaleOverride,
      builder: (BuildContext context, Locale? override, _) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
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
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRouter.onGenerateRoute,
        );
      },
    );
  }
}
