import 'dart:io';

import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_mobile/core/providers/root_container.dart';
import 'package:chisto_mobile/core/network/connectivity_gate.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
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
  Hive.init(dir.path);
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
  await AppBootstrap.instance.initialize(config: AppConfig.local);
  setRootProviderContainer(AppBootstrap.instance.providerContainer);
}

/// Wraps [child] for widget tests that need Riverpod + l10n (post–AppBootstrap migration).
Widget wrapForWidgetTest(
  Widget child, {
  Locale locale = const Locale('en'),
}) {
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
