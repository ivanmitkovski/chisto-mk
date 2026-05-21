import 'package:chisto_mobile/features/notifications/data/push_notification_payload.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolveTitleBody prefers notification block then data', () {
    final ({String? title, String? body}) resolved =
        PushNotificationPayload.resolveTitleBody(
      RemoteMessage(
        notification: const RemoteNotification(
          title: 'Alert title',
          body: 'Alert body',
        ),
        data: <String, String>{'title': 'Data title', 'body': 'Data body'},
      ),
    );
    expect(resolved.title, 'Alert title');
    expect(resolved.body, 'Alert body');
  });

  test('resolveTitleBody fills AUDIO preview when notification body is empty', () {
    final ({String? title, String? body}) resolved =
        PushNotificationPayload.resolveTitleBody(
      RemoteMessage(
        notification: const RemoteNotification(
          title: 'River cleanup',
          body: 'Alex: ',
        ),
        data: <String, String>{
          'type': 'EVENT_CHAT',
          'messageType': 'AUDIO',
          'senderName': 'Alex',
          'messagePreview': '',
        },
      ),
    );
    expect(resolved.body, 'Alex: Voice message');
  });

  test('resolveTitleBody uses messageType fallback when preview missing', () {
    final ({String? title, String? body}) resolved =
        PushNotificationPayload.resolveTitleBody(
      RemoteMessage(
        data: <String, String>{
          'type': 'EVENT_CHAT',
          'messageType': 'IMAGE',
          'senderName': 'Sam',
        },
      ),
    );
    expect(resolved.body, 'Sam: Photo');
  });

  test('resolveTitleBody uses messagePreview for EVENT_CHAT', () {
    final ({String? title, String? body}) resolved =
        PushNotificationPayload.resolveTitleBody(
      RemoteMessage(
        data: <String, String>{
          'type': 'EVENT_CHAT',
          'title': 'Chat',
          'messagePreview': 'Hello there',
        },
      ),
    );
    expect(resolved.title, 'Chat');
    expect(resolved.body, 'Hello there');
  });

  test('shouldPresentForegroundBanner is false for badge_sync', () {
    expect(
      PushNotificationPayload.shouldPresentForegroundBanner(
        RemoteMessage(data: <String, String>{'kind': 'badge_sync'}),
      ),
      isFalse,
    );
  });

  test('shouldPresentForegroundBanner is true for data-only title and body', () {
    expect(
      PushNotificationPayload.shouldPresentForegroundBanner(
        RemoteMessage(
          data: <String, String>{
            'type': 'COMMENT',
            'title': 'New comment',
            'body': 'Someone replied',
          },
        ),
      ),
      isTrue,
    );
  });

  test('shouldPresentForegroundBanner is true when title and body resolve', () {
    expect(
      PushNotificationPayload.shouldPresentForegroundBanner(
        RemoteMessage(
          notification: const RemoteNotification(
            title: 'New comment',
            body: 'Hello',
          ),
          data: <String, String>{'type': 'COMMENT'},
        ),
      ),
      isTrue,
    );
  });

  test('parseUnreadCountFromData accepts int and string', () {
    expect(
      PushNotificationPayload.parseUnreadCountFromData(<String, dynamic>{
        'unreadCount': 5,
      }),
      5,
    );
    expect(
      PushNotificationPayload.parseUnreadCountFromData(<String, dynamic>{
        'unreadCount': '7',
      }),
      7,
    );
  });

  test('eventChatOsGroupId uses eventId or threadKey', () {
    expect(
      PushNotificationPayload.eventChatOsGroupId(<String, dynamic>{
        'eventId': 'evt-abc',
      }),
      'event_chat_evt-abc',
    );
    expect(
      PushNotificationPayload.eventChatOsGroupId(<String, dynamic>{
        'threadKey': 'event-chat:evt-abc',
      }),
      'event_chat_evt-abc',
    );
    expect(
      PushNotificationPayload.parseMessageCount(<String, dynamic>{
        'messageCount': '4',
      }),
      4,
    );
  });

  test('eventChatNotificationTag is unique per message', () {
    expect(
      PushNotificationPayload.eventChatNotificationTag(<String, dynamic>{
        'messageId': 'msg-99',
      }),
      'event_chat_msg_msg-99',
    );
    expect(
      PushNotificationPayload.eventChatNotificationTag(<String, dynamic>{
        'notificationId': 'n-1',
      }),
      'event_chat_notif_n-1',
    );
  });

  test('encode and decode payload round-trip', () {
    final Map<String, dynamic> data = <String, dynamic>{
      'notificationId': 'n-2',
      'type': 'REPORT_STATUS',
    };
    final String? encoded = PushNotificationPayload.encodePayload(data);
    expect(encoded, isNotNull);
    expect(PushNotificationPayload.decodePayload(encoded), data);
  });
}
