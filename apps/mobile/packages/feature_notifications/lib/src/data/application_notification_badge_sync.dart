import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/providers/refresh_signals_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:flutter/foundation.dart';

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
  final container = rootProviderContainer;
  container.listen<int>(notificationsUnreadCountProvider, (int? _, int count) {
    // ignore: discarded_futures, fire-and-forget OS badge update on unread-count change
    syncApplicationBadge(count);
  });
  // ignore: discarded_futures, fire-and-forget initial OS badge sync
  syncApplicationBadge(container.read(notificationsUnreadCountProvider));
}
