import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_notifications/src/data/event_chat_notification_details.dart';
import 'package:feature_notifications/src/data/push_notification_payload.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
