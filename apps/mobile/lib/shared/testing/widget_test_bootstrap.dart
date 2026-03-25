import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool _bootstrapped = false;

Future<void> bootstrapWidgetTests() async {
  if (_bootstrapped) return;
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await ServiceLocator.instance.initialize(config: AppConfig.local);
  _bootstrapped = true;
}

