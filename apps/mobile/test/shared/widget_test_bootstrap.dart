import 'dart:io';

import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
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

Future<void> bootstrapWidgetTests() async {
  if (_bootstrapped) return;
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  FlutterLocalNotificationsPlatform.instance =
      FakeFlutterLocalNotificationsPlatform();
  final Directory dir = await Directory.systemTemp.createTemp('chisto_widget_test_');
  PathProviderPlatform.instance = _WidgetTestPathProvider(dir.path);
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await ServiceLocator.instance.initialize(config: AppConfig.local);
  _bootstrapped = true;
}
