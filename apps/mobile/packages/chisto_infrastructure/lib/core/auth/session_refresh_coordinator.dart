import 'package:flutter/foundation.dart';

/// Coordinates foreground vs background token refresh to avoid rotation races.
abstract final class SessionRefreshCoordinator {
  static DateTime? _lastForegroundRefreshAt;

  static const Duration foregroundPriorityWindow = Duration(seconds: 30);

  static void markForegroundRefresh() {
    _lastForegroundRefreshAt = DateTime.now();
  }

  static bool shouldSkipBackgroundRefresh() {
    final DateTime? at = _lastForegroundRefreshAt;
    if (at == null) {
      return false;
    }
    return DateTime.now().difference(at) < foregroundPriorityWindow;
  }

  @visibleForTesting
  static void resetForTest() {
    _lastForegroundRefreshAt = null;
  }
}
