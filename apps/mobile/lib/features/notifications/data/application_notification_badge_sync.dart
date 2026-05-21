import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_mobile/core/providers/refresh_signals_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:chisto_mobile/core/logging/app_log.dart';

bool _badgeSyncInstalled = false;

/// Updates the OS home-screen app icon badge.
Future<void> syncApplicationBadge(int count) async {
  try {
    if (count <= 0) {
      await AppBadgePlus.updateBadge(0);
    } else {
      await AppBadgePlus.updateBadge(count);
    }
  } catch (e) {
    if (kDebugMode) {
      AppLog.verbose('[Push] App icon badge sync failed: $e');
    }
  }
}

/// Listens to [notificationsUnreadCountProvider] and keeps the app icon in sync.
void installApplicationBadgeSync() {
  if (_badgeSyncInstalled) return;
  _badgeSyncInstalled = true;
  final container = AppBootstrap.instance.providerContainer;
  container.listen<int>(notificationsUnreadCountProvider, (int? _, int count) {
    // ignore: discarded_futures
    syncApplicationBadge(count);
  });
  // ignore: discarded_futures
  syncApplicationBadge(container.read(notificationsUnreadCountProvider));
}
