import 'package:shared_preferences/shared_preferences.dart';

/// When enabled with cellular connectivity, report image prefetch is skipped.
class DataSaverPreference {
  DataSaverPreference._();

  static const String _key = 'reports_data_saver_images';

  static bool isEnabled(SharedPreferences prefs) {
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> setEnabled(SharedPreferences prefs, bool value) {
    return prefs.setBool(_key, value);
  }
}
