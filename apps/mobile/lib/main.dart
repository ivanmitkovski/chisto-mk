import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chisto_mobile/core/app_theme.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/l10n/app_locale_resolution.dart';
import 'package:chisto_mobile/core/deep_links/deep_link_router.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/features/notifications/data/notification_open_router.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  runApp(const ChistoApp());
}

class ChistoApp extends StatefulWidget {
  const ChistoApp({super.key});

  @override
  State<ChistoApp> createState() => _ChistoAppState();
}

class _ChistoAppState extends State<ChistoApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<RemoteMessage>? _tapSubscription;
  StreamSubscription<Uri>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _tapSubscription = ServiceLocator.instance.pushNotificationService
        .notificationTaps
        .listen(_onNotificationTap);
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
    final bool handled = DeepLinkRouter.handleUri(
      nav,
      uri,
      isAuthenticated: ServiceLocator.instance.authState.isAuthenticated,
    );
    if (!handled && kDebugMode) {
      debugPrint('[DeepLink] Unhandled URI: $uri');
    }
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    _tapSubscription?.cancel();
    super.dispose();
  }

  void _onNotificationTap(RemoteMessage message) {
    final BuildContext? ctx = _navigatorKey.currentContext;
    if (ctx == null) return;
    NotificationOpenRouter.handleOpen(ctx, message);
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
