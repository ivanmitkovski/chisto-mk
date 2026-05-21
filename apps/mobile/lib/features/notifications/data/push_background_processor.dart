import 'dart:io';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:chisto_mobile/features/notifications/data/push_background_pending_store.dart';
import 'package:chisto_mobile/features/notifications/data/event_chat_local_notification_presenter.dart';
import 'package:chisto_mobile/features/notifications/data/event_chat_notification_details.dart';
import 'package:chisto_mobile/features/notifications/data/event_chat_push_reply_service.dart';
import 'package:chisto_mobile/features/notifications/data/push_notification_payload.dart';
import 'package:chisto_mobile/core/logging/app_log.dart';

bool _localNotificationsReady = false;
final FlutterLocalNotificationsPlugin _backgroundLocalNotifications =
    FlutterLocalNotificationsPlugin();

/// Processes an FCM message in the background isolate (no AppBootstrap).
Future<void> processBackgroundPushMessage(RemoteMessage message) async {
  await PushBackgroundPendingStore.recordBackgroundMessage(message);

  final Map<String, dynamic> data = Map<String, dynamic>.from(message.data);
  final int? unread = PushNotificationPayload.parseUnreadCountFromData(data);
  final String? kind = data['kind'] as String?;
  final String? type = data['type'] as String?;

  if (type == 'EVENT_CHAT') {
    await _ensureBackgroundLocalNotifications();
    final EventChatNotificationDetails eventChatDetails = EventChatNotificationDetails(
      androidChannel: PushNotificationPayload.resolveAndroidChannel('EVENT_CHAT'),
      replyActionTitle: 'Reply',
      replyInputLabel: 'Message',
    );
    await EventChatLocalNotificationPresenter.show(
      _backgroundLocalNotifications,
      message: message,
      eventChatDetails: eventChatDetails,
    );
  } else if (Platform.isAndroid && message.notification == null) {
    await _maybeShowAndroidLocalNotification(message);
  }

  if (unread != null) {
    try {
      await AppBadgePlus.updateBadge(unread <= 0 ? 0 : unread);
    } on Object catch (e) {
      if (kDebugMode) {
        AppLog.verbose('[Push] Background badge sync failed: $e');
      }
    }
  }

  if (kDebugMode) {
    AppLog.verbose(
      '[Push] Background processed: ${message.messageId} kind=$kind unread=$unread',
    );
  }
}

Future<void> _maybeShowAndroidLocalNotification(RemoteMessage message) async {
  final ({String? title, String? body}) resolved =
      PushNotificationPayload.resolveTitleBody(message);
  final String? title = resolved.title;
  final String? body = resolved.body;
  if (title == null || title.isEmpty || body == null || body.isEmpty) {
    return;
  }

  await _ensureBackgroundLocalNotifications();

  final String? type = message.data['type'] as String?;
  final AndroidChannelInfo ch = PushNotificationPayload.resolveAndroidChannel(type);
  final String? notificationId = message.data['notificationId'] as String?;
  final int androidId = notificationId != null && notificationId.isNotEmpty
      ? notificationId.hashCode & 0x3fffffff
      : (message.messageId?.hashCode ?? message.hashCode) & 0x3fffffff;

  await _backgroundLocalNotifications.show(
    androidId,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        ch.id,
        ch.name,
        channelDescription: ch.description,
        importance: ch.importance,
        priority: Priority.high,
      ),
    ),
    payload: PushNotificationPayload.encodePayload(message.data),
  );
}

Future<void> _ensureBackgroundLocalNotifications() async {
  if (_localNotificationsReady) return;

  if (Platform.isAndroid) {
    final AndroidFlutterLocalNotificationsPlugin? android =
        _backgroundLocalNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    const List<AndroidNotificationChannel> channels = <AndroidNotificationChannel>[
      AndroidNotificationChannel(
        'chisto_default',
        'Chisto Notifications',
        description: 'Default notification channel for Chisto.mk',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'chisto_event_chat',
        'Event Chat',
        description: 'Event chat messages',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'chisto_reports',
        'Report Updates',
        description: 'Report updates',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'chisto_events',
        'Cleanup Events',
        description: 'Cleanup events',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'chisto_social',
        'Social Activity',
        description: 'Social activity',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        'chisto_system',
        'System',
        description: 'System',
        importance: Importance.defaultImportance,
      ),
    ];
    for (final AndroidNotificationChannel c in channels) {
      await android?.createNotificationChannel(c);
    }
  }

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
    notificationCategories: EventChatNotificationDetails.darwinCategories(
      replyTitle: 'Reply',
      replyButtonTitle: 'Send',
      replyPlaceholder: 'Message',
    ),
  );

  await _backgroundLocalNotifications.initialize(
    InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    ),
    onDidReceiveBackgroundNotificationResponse:
        onEventChatPushBackgroundNotificationResponse,
  );
  _localNotificationsReady = true;
}

@visibleForTesting
void resetBackgroundLocalNotificationsForTest() {
  _localNotificationsReady = false;
}
