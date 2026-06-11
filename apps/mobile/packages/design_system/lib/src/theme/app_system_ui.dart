import 'package:design_system/src/theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Platform system chrome (status / navigation bars) for the light app shell.
abstract final class AppSystemUi {
  /// Opaque navigation bar so Android home/back/recents stay readable on feed UI.
  static const SystemUiOverlayStyle light = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.panelBackground,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: true,
  );

  /// Applies [light] on Android during cold start (before first frame).
  static void applyLightAndroidNavigationBar() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    SystemChrome.setSystemUIOverlayStyle(light);
  }
}
