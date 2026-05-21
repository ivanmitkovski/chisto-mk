import 'package:chisto_mobile/features/notifications/data/event_chat_push_actions.dart';
import 'package:chisto_mobile/features/notifications/data/event_chat_push_reply_service.dart';
import 'package:chisto_mobile/features/notifications/data/push_notification_payload.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventChatPushReplyService.isInlineReplyForTest', () {
    test('true when input and eventId present', () {
      final NotificationResponse response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotificationAction,
        actionId: EventChatPushActions.replyActionId,
        input: '  hi  ',
        payload: PushNotificationPayload.encodePayload(<String, dynamic>{
          'type': 'EVENT_CHAT',
          'eventId': 'ev-1',
        }),
      );
      expect(EventChatPushReplyService.isInlineReplyForTest(response), isTrue);
    });

    test('true when actionId omitted but input and eventId present', () {
      final NotificationResponse response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotificationAction,
        input: 'hello',
        payload: PushNotificationPayload.encodePayload(<String, dynamic>{
          'eventId': 'ev-2',
        }),
      );
      expect(EventChatPushReplyService.isInlineReplyForTest(response), isTrue);
    });

    test('false when input empty', () {
      final NotificationResponse response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: PushNotificationPayload.encodePayload(<String, dynamic>{
          'eventId': 'ev-1',
        }),
      );
      expect(EventChatPushReplyService.isInlineReplyForTest(response), isFalse);
    });

    test('false when eventId missing', () {
      final NotificationResponse response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotificationAction,
        actionId: EventChatPushActions.replyActionId,
        input: 'text',
        payload: PushNotificationPayload.encodePayload(<String, dynamic>{
          'type': 'EVENT_CHAT',
        }),
      );
      expect(EventChatPushReplyService.isInlineReplyForTest(response), isFalse);
    });

    test('false when actionId is a non-reply action', () {
      final NotificationResponse response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotificationAction,
        actionId: 'OTHER_ACTION',
        input: 'text',
        payload: PushNotificationPayload.encodePayload(<String, dynamic>{
          'eventId': 'ev-1',
        }),
      );
      expect(EventChatPushReplyService.isInlineReplyForTest(response), isFalse);
    });
  });
}
