import 'dart:async';
import 'dart:io';

import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:feature_notifications/src/application/notifications_providers.dart';
import 'package:feature_notifications/src/data/event_chat_mark_read_result.dart';
import 'package:feature_notifications/src/data/notification_inbox_refresh.dart';
import 'package:feature_notifications/src/data/notification_unread_publish.dart';
import 'package:feature_notifications/src/data/push_notification_payload.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// After event chat read cursor advances, sync inbox badge and dismiss tray entries.
abstract final class EventChatNotificationSync {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> afterMarkRead({
    required String eventId,
    EventChatMarkReadResult? result,
  }) async {
    final String trimmed = eventId.trim();
    if (trimmed.isEmpty) return;

    final int? unread = result?.unreadCount;
    if (unread != null) {
      publishNotificationsUnreadCountRespectingSuppress(unread);
    } else {
      unawaited(
        readRoot(notificationsInboxCoordinatorProvider).refreshUnreadBadge(),
      );
    }

    bumpNotificationsInboxRefreshTick(<String, dynamic>{
      'type': 'EVENT_CHAT',
      'eventId': trimmed,
      'source': 'chat_mark_read',
    });

    await dismissEventChatTrayNotifications(trimmed);
  }

  /// Best-effort removal of locally shown chat notifications for [eventId].
  static Future<void> dismissEventChatTrayNotifications(String eventId) async {
    try {
      if (Platform.isAndroid) {
        final String? tag = PushNotificationPayload.eventChatNotificationTag(
          <String, dynamic>{'eventId': eventId},
        );
        if (tag != null && tag.isNotEmpty) {
          final AndroidFlutterLocalNotificationsPlugin? android =
              _localNotifications
                  .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin
                  >();
          await android?.cancel(0, tag: tag);
        }
      }
      // iOS groups remote alerts; local foreground banners use per-notification id hash.
      // No stable cancel-all-by-thread API — badge sync handles icon count.
    } on Object catch (e) {
      if (kDebugMode) {
        AppLog.verbose('[Push] dismiss event chat tray failed: $e');
      }
    }
  }
}
