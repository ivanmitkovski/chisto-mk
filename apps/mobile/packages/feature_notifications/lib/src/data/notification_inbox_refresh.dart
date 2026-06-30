import 'package:chisto_infrastructure/core/providers/refresh_signals_providers.dart';
import 'package:feature_notifications/src/data/application_notification_badge_sync.dart';
import 'package:feature_notifications/src/data/notification_unread_publish.dart';
import 'package:feature_notifications/src/data/push_notification_payload.dart';

/// FCM data keys that indicate an inbox row was created server-side.
bool notificationPushImpliesInboxUpdate(Map<String, dynamic> data) {
  final String? notificationId = data['notificationId'] as String?;
  if (notificationId != null && notificationId.isNotEmpty) {
    return true;
  }
  final String? type = data['type'] as String?;
  return type != null && type.isNotEmpty;
}

/// Applies [unreadCount] from FCM/socket payload when present (immediate bell sync).
void applyPushUnreadCountIfPresent(Map<String, dynamic> data) {
  final int? unread = PushNotificationPayload.parseUnreadCountFromData(data);
  if (unread != null) {
    publishNotificationsUnreadCountRespectingSuppress(unread);
  }
}

/// Signals listeners to refresh the inbox list and/or unread badge.
///
/// [NotificationsScreen] reloads when visible; otherwise
/// [NotificationsInboxCoordinator] updates the bell via unread-count only.
void bumpNotificationsInboxRefreshTick([Map<String, dynamic>? data]) {
  if (data != null) {
    applyPushUnreadCountIfPresent(data);
  }
  bumpNotificationsInboxRefresh();
}

/// Keeps the feed notification bell in sync with the inbox (including while it is open).
void publishNotificationsUnreadCount(int count) {
  if (readNotificationsUnreadCount() != count) {
    setNotificationsUnreadCount(count);
  }
  // ignore: discarded_futures, fire-and-forget OS badge update
  syncApplicationBadge(count);
}
