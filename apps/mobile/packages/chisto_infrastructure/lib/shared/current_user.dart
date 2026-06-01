import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';

/// Current logged-in user. Reads from [AuthState] when app is initialized.
class CurrentUser {
  CurrentUser._();

  static const String _fallbackId = 'current_user';
  static const String _fallbackDisplayName = 'You';

  static String get id {
    final String? userId = tryReadRoot(authStateProvider)?.userId;
    return userId ?? _fallbackId;
  }

  static String get displayName {
    final String? name = tryReadRoot(authStateProvider)?.displayName;
    return name ?? _fallbackDisplayName;
  }
}
