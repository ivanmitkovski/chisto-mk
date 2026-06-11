import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Marketing version from the app bundle (e.g. `1.0.0` from pubspec).
final profileAppVersionProvider = FutureProvider<String>((ref) async {
  final PackageInfo info = await PackageInfo.fromPlatform();
  return info.version;
});
