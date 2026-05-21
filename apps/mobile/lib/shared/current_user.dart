import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';

/// Current logged-in user. Reads from [AuthState] when app is initialized.
class CurrentUser {
  CurrentUser._();

  static const String _fallbackId = 'current_user';
  static const String _fallbackDisplayName = 'You';

  static String get id {
    if (!AppBootstrap.instance.isInitialized) return _fallbackId;
    return AppBootstrap.instance.authState.userId ?? _fallbackId;
  }

  static String get displayName {
    if (!AppBootstrap.instance.isInitialized) return _fallbackDisplayName;
    return AppBootstrap.instance.authState.displayName ?? _fallbackDisplayName;
  }
}
