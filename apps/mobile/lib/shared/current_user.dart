import 'package:chisto_mobile/core/di/service_locator.dart';

/// Current logged-in user. Reads from [AuthState] when app is initialized.
class CurrentUser {
  CurrentUser._();

  static const String _fallbackId = 'current_user';
  static const String _fallbackDisplayName = 'You';

  static String get id {
    if (!ServiceLocator.instance.isInitialized) return _fallbackId;
    return ServiceLocator.instance.authState.userId ?? _fallbackId;
  }

  static String get displayName {
    if (!ServiceLocator.instance.isInitialized) return _fallbackDisplayName;
    return ServiceLocator.instance.authState.displayName ?? _fallbackDisplayName;
  }
}
