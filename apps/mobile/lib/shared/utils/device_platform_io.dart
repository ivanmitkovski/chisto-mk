import 'dart:io' show Platform;

abstract final class DevicePlatform {
  static bool get isIOS => Platform.isIOS;
}
