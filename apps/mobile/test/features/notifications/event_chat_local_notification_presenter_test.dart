import 'package:feature_notifications/src/data/event_chat_local_notification_presenter.dart';
import 'package:feature_notifications/src/data/event_chat_notification_details.dart';
import 'package:feature_notifications/src/data/push_notification_payload.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/fake_flutter_local_notifications_platform.dart';

const EventChatNotificationDetails _details = EventChatNotificationDetails(
  androidChannel: AndroidChannelInfo(
    'chisto_event_chat',
    'Event Chat',
    'Event chat messages',
    Importance.high,
  ),
  replyActionTitle: 'Reply',
  replyInputLabel: 'Message',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FlutterLocalNotificationsPlugin plugin;

  setUp(() {
    FlutterLocalNotificationsPlatform.instance =
        FakeFlutterLocalNotificationsPlatform();
    plugin = FlutterLocalNotificationsPlugin();
  });

  test('show returns false for non EVENT_CHAT type', () async {
    final bool shown = await EventChatLocalNotificationPresenter.show(
      plugin,
      message: const RemoteMessage(
        data: <String, String>{
          'type': 'COMMENT',
          'title': 'New comment',
          'body': 'Hello',
        },
      ),
      eventChatDetails: _details,
    );

    expect(shown, isFalse);
  });

  test('show returns false when title missing or empty', () async {
    final bool missingTitle = await EventChatLocalNotificationPresenter.show(
      plugin,
      message: const RemoteMessage(
        data: <String, String>{'type': 'EVENT_CHAT', 'messagePreview': 'Hello'},
      ),
      eventChatDetails: _details,
    );
    final bool emptyTitle = await EventChatLocalNotificationPresenter.show(
      plugin,
      message: const RemoteMessage(
        data: <String, String>{
          'type': 'EVENT_CHAT',
          'title': '',
          'messagePreview': 'Hello',
        },
      ),
      eventChatDetails: _details,
    );

    expect(missingTitle, isFalse);
    expect(emptyTitle, isFalse);
  });

  test('show returns true and encodes payload for EVENT_CHAT', () async {
    const RemoteMessage message = RemoteMessage(
      messageId: 'msg-bg-1',
      data: <String, String>{
        'type': 'EVENT_CHAT',
        'title': 'River cleanup',
        'messagePreview': 'See you there',
        'eventId': 'evt-abc',
        'notificationId': 'notif-99',
      },
    );

    final bool shown = await EventChatLocalNotificationPresenter.show(
      plugin,
      message: message,
      eventChatDetails: _details,
    );

    expect(shown, isTrue);
    final String? payload = PushNotificationPayload.encodePayload(message.data);
    expect(payload, isNotNull);
    expect(PushNotificationPayload.decodePayload(payload), message.data);
  });

  test('show uses notificationId hash for android id', () async {
    const String notificationId = 'notif-stable-id';
    final int expectedId = notificationId.hashCode & 0x3fffffff;

    final bool shown = await EventChatLocalNotificationPresenter.show(
      plugin,
      message: const RemoteMessage(
        data: <String, String>{
          'type': 'EVENT_CHAT',
          'title': 'Chat',
          'messagePreview': 'Ping',
          'notificationId': notificationId,
        },
      ),
      eventChatDetails: _details,
    );

    expect(shown, isTrue);
    expect(expectedId, notificationId.hashCode & 0x3fffffff);
  });
}
