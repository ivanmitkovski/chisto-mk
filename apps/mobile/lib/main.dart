import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chisto_mobile/core/app_theme.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/features/notifications/data/notification_open_router.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
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
  StreamSubscription<RemoteMessage>? _tapSubscription;

  @override
  void initState() {
    super.initState();
    _tapSubscription = ServiceLocator.instance.pushNotificationService
        .notificationTaps
        .listen(_onNotificationTap);
  }

  @override
  void dispose() {
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
          title: 'Chisto.mk',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: override,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          localeListResolutionCallback:
              (List<Locale>? locales, Iterable<Locale> supported) {
            if (override != null) {
              return override;
            }
            for (final Locale device in locales ?? <Locale>[]) {
              for (final Locale s in supported) {
                if (s.languageCode == device.languageCode) {
                  return s;
                }
              }
            }
            return const Locale('en');
          },
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRouter.onGenerateRoute,
        );
      },
    );
  }
}
