import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chisto_mobile/core/app_theme.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/image/image_cache_governor.dart';
import 'package:chisto_mobile/core/lifecycle/reports_realtime_lifecycle.dart';
import 'package:chisto_mobile/core/l10n/app_locale_resolution.dart';
import 'package:chisto_mobile/core/deep_links/deep_link_router.dart';
import 'package:chisto_mobile/core/deep_links/share_token_from_route.dart';
import 'package:chisto_mobile/core/navigation/app_navigator_key.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/features/notifications/data/notification_open_router.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
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
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[Firebase] Init error (expected in dev/simulator): $e');
  }
  await ServiceLocator.instance.initialize();
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
  StreamSubscription<RemoteMessage>? _tapSubscription;
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
    final push = ServiceLocator.instance.pushNotificationService;
    unawaited(push.initialize());
    push.foregroundMessages.listen((RemoteMessage message) {
      final Map<String, dynamic> data = message.data;
      if (data['type'] == 'CLEANUP_EVENT' && data['kind'] == 'published') {
        ServiceLocator.instance.eventsFeedRemoteRefreshTick.value++;
      }
    });
    _tapSubscription = push.notificationTaps.listen(_onNotificationTap);
    // iOS (FlutterImplicitEngineDelegate): native plugins register in
    // `didInitializeImplicitFlutterEngine`, which can run after the first
    // frame. Subscribing to `app_links` in initState races and causes
    // MissingPluginException on `com.llfbandit.app_links/events`.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initDeepLinks());
    });
  }

  Future<void> _initDeepLinks() async {
    try {
      final Uri? initial = await _appLinks.getInitialLink();
      if (initial != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _dispatchDeepLink(initial));
      }
    } on MissingPluginException catch (e) {
      debugPrint('[DeepLink] app_links native side not ready or missing (try full rebuild): $e');
      return;
    } catch (e) {
      debugPrint('[DeepLink] getInitialLink failed: $e');
    }
    try {
      _deepLinkSubscription = _appLinks.uriLinkStream.listen(
        _dispatchDeepLink,
        onError: (Object e) => debugPrint('[DeepLink] stream error: $e'),
      );
    } on MissingPluginException catch (e) {
      debugPrint('[DeepLink] app_links stream unavailable (try full rebuild): $e');
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
      debugPrint('[DeepLink] Unhandled URI: $uri');
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
    ImageCacheGovernor.instance.uninstall();
    _deepLinkSubscription?.cancel();
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
        debugPrint('[Push] Open dropped: navigator context not ready');
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
