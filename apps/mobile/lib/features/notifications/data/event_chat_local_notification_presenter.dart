import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:chisto_mobile/core/logging/app_log.dart';
import 'package:chisto_mobile/features/notifications/data/event_chat_notification_details.dart';
import 'package:chisto_mobile/features/notifications/data/push_notification_payload.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

/// Shows EVENT_CHAT as a local notification with inline-reply actions.
abstract final class EventChatLocalNotificationPresenter {
  static Future<bool> show(
    FlutterLocalNotificationsPlugin plugin, {
    required RemoteMessage message,
    required EventChatNotificationDetails eventChatDetails,
    AppLocalizations? strings,
  }) async {
    final String? type = message.data['type'] as String?;
    if (type != 'EVENT_CHAT') {
      return false;
    }

    final ({String? title, String? body}) resolved =
        PushNotificationPayload.resolveTitleBody(message, strings: strings);
    final String? title = resolved.title;
    final String? body = resolved.body;
    if (title == null || title.isEmpty || body == null || body.isEmpty) {
      return false;
    }

    final String? notificationId = message.data['notificationId'] as String?;
    final int androidId = notificationId != null && notificationId.isNotEmpty
        ? notificationId.hashCode & 0x3fffffff
        : (message.messageId?.hashCode ?? message.hashCode) & 0x3fffffff;

    try {
      await plugin.show(
        androidId,
        title,
        body,
        eventChatDetails.forData(message.data),
        payload: PushNotificationPayload.encodePayload(message.data),
      );
      return true;
    } on Object catch (e) {
      if (kDebugMode) {
        AppLog.verbose('[Push] EVENT_CHAT local show failed: $e');
      }
      return false;
    }
  }
}
