import 'dart:io';

import 'package:chisto_infrastructure/core/auth/auth_session_scope.dart';
import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/navigation/app_go_router.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:chisto_infrastructure/core/network/connectivity_gate.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:feature_home/src/application/home_shell_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fake_flutter_local_notifications_platform.dart';

bool _bootstrapped = false;

class _WidgetTestPathProvider extends PathProviderPlatform {
  _WidgetTestPathProvider(this._root);

  final String _root;

  @override
  Future<String?> getApplicationDocumentsPath() async => _root;

  @override
  Future<String?> getTemporaryPath() async => '$_root/tmp';

  @override
  Future<String?> getApplicationSupportPath() async => '$_root/support';

  @override
  Future<String?> getApplicationCachePath() async => '$_root/cache';
}

/// Native/plugin plumbing for widget tests (no [AppBootstrap.initialize]).
Future<void> ensureWidgetTestPlumbing() async {
  if (_bootstrapped) return;
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  FlutterLocalNotificationsPlatform.instance =
      FakeFlutterLocalNotificationsPlatform();
  final Directory dir = await Directory.systemTemp.createTemp(
    'chisto_widget_test_',
  );
  PathProviderPlatform.instance = _WidgetTestPathProvider(dir.path);
  ConnectivityGate.check = () async => <ConnectivityResult>[
    ConnectivityResult.wifi,
  ];
  ConnectivityGate.watch = () => Stream<List<ConnectivityResult>>.value(
    <ConnectivityResult>[ConnectivityResult.wifi],
  );
  _bootstrapped = true;
}

Future<void> bootstrapWidgetTests() async {
  await ensureWidgetTestPlumbing();
  if (AppBootstrap.instance.isInitialized) {
    setRootProviderContainer(AppBootstrap.instance.providerContainer);
    return;
  }
  SharedPreferences.setMockInitialValues(<String, Object>{});
  FlutterSecureStorage.setMockInitialValues(<String, String>{});
  await AppBootstrap.instance.initialize(config: AppConfig.local);
  setRootProviderContainer(AppBootstrap.instance.providerContainer);
}

/// Wraps [child] for widget tests that need Riverpod + l10n (post–AppBootstrap migration).
Widget wrapForWidgetTest(Widget child, {Locale locale = const Locale('en')}) {
  return UncontrolledProviderScope(
    container: AppBootstrap.instance.providerContainer,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

/// Pumps [MaterialApp.router] with the production route table for navigation tests.
Future<GoRouter> pumpAppRouter(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  String initialLocation = '/',
  bool disableAnimations = false,
}) async {
  await bootstrapWidgetTests();
  readRoot(homeShellControllerProvider.notifier);
  final GoRouter router = buildAppGoRouter(initialLocation: initialLocation);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: AppBootstrap.instance.providerContainer,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: disableAnimations
            ? (BuildContext context, Widget? child) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(disableAnimations: true),
                  child: child ?? const SizedBox.shrink(),
                );
              }
            : null,
      ),
    ),
  );
  await tester.pump();
  return router;
}

/// Binds [appGoRouter] and pumps [AuthSessionScope] over [MaterialApp.router].
Future<GoRouter> pumpAuthSessionScopeRouter(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  String initialLocation = AppRoutes.signIn,
}) async {
  await bootstrapWidgetTests();
  readRoot(homeShellControllerProvider.notifier);
  final GoRouter router = buildAppGoRouter(initialLocation: initialLocation);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: AppBootstrap.instance.providerContainer,
      child: AuthSessionScope(
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pump();
  return router;
}
