import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_mobile/core/logging/app_log.dart';
import 'package:chisto_mobile/features/events/data/chat/chat_client_message_id.dart';
import 'package:chisto_mobile/features/notifications/data/event_chat_notification_sync.dart';
import 'package:chisto_mobile/features/notifications/data/event_chat_push_actions.dart';
import 'package:chisto_mobile/features/notifications/data/event_chat_push_reply_background_sender.dart';
import 'package:chisto_mobile/features/notifications/data/pending_chat_reply_store.dart';
import 'package:chisto_mobile/features/notifications/data/push_notification_payload.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Sends event-chat messages from notification inline reply.
abstract final class EventChatPushReplyService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Returns true when the response was handled as an inline reply (not a tap).
  static Future<bool> handleNotificationResponse(
    NotificationResponse response, {
    required bool mainIsolate,
  }) async {
    if (!_isInlineReply(response)) {
      return false;
    }

    if (kDebugMode) {
      AppLog.verbose(
        '[Push] inline reply actionId=${response.actionId} '
        'type=${response.notificationResponseType}',
      );
    }

    final String text = response.input!.trim();
    final Map<String, dynamic>? data =
        PushNotificationPayload.decodePayload(response.payload);
    final String? eventId = data?['eventId'] as String?;
    if (eventId == null || eventId.isEmpty) {
      return false;
    }
    final String? notificationId = data?['notificationId'] as String?;

    if (!mainIsolate) {
      final bool sent = await EventChatPushReplyBackgroundSender.trySend(
        eventId: eventId,
        body: text,
      );
      if (!sent) {
        await PendingChatReplyStore.enqueue(
          PendingChatReply(
            eventId: eventId,
            body: text,
            notificationId: notificationId,
          ),
        );
      }
      return true;
    }

    await sendReply(
      eventId: eventId,
      body: text,
      notificationId: notificationId,
      androidNotificationId: response.id,
    );
    return true;
  }

  static bool _isInlineReply(NotificationResponse response) {
    final String? text = response.input?.trim();
    if (text == null || text.isEmpty) {
      return false;
    }
    final Map<String, dynamic>? data =
        PushNotificationPayload.decodePayload(response.payload);
    final String? eventId = data?['eventId'] as String?;
    if (eventId == null || eventId.isEmpty) {
      return false;
    }
    final String? actionId = response.actionId;
    if (actionId != null &&
        actionId.isNotEmpty &&
        actionId != EventChatPushActions.replyActionId) {
      return false;
    }
    return true;
  }

  @visibleForTesting
  static bool isInlineReplyForTest(NotificationResponse response) =>
      _isInlineReply(response);

  static Future<void> sendReply({
    required String eventId,
    required String body,
    String? notificationId,
    int? androidNotificationId,
  }) async {
    final bootstrap = AppBootstrap.instance;
    if (!bootstrap.authState.isAuthenticated) {
      await PendingChatReplyStore.enqueue(
        PendingChatReply(eventId: eventId, body: body, notificationId: notificationId),
      );
      return;
    }

    try {
      final repo = bootstrap.eventChatRepository;
      final saved = await repo.sendMessage(
        eventId,
        body,
        clientMessageId: newChatClientMessageId(),
      );
      final result = await repo.markRead(eventId, saved.id);
      await EventChatNotificationSync.afterMarkRead(
        eventId: eventId,
        result: result,
      );
      if (notificationId != null && notificationId.isNotEmpty) {
        try {
          await bootstrap.notificationsRepository.markAsRead(notificationId);
        } on Object catch (_) {}
      }
      if (androidNotificationId != null) {
        await _localNotifications.cancel(androidNotificationId);
      }
      await EventChatNotificationSync.dismissEventChatTrayNotifications(eventId);
    } on Object catch (e, st) {
      if (kDebugMode) {
        AppLog.verbose('[Push] event chat reply failed: $e\n$st');
      }
      await PendingChatReplyStore.enqueue(
        PendingChatReply(eventId: eventId, body: body, notificationId: notificationId),
      );
    }
  }

  static Future<void> drainPendingReplies() async {
    if (!AppBootstrap.instance.authState.isAuthenticated) {
      return;
    }
    final List<PendingChatReply> pending = await PendingChatReplyStore.drainAll();
    for (final PendingChatReply item in pending) {
      await sendReply(
        eventId: item.eventId,
        body: item.body,
        notificationId: item.notificationId,
      );
    }
  }
}

@pragma('vm:entry-point')
void onEventChatPushBackgroundNotificationResponse(NotificationResponse response) {
  // ignore: discarded_futures
  EventChatPushReplyService.handleNotificationResponse(
    response,
    mainIsolate: false,
  );
}
