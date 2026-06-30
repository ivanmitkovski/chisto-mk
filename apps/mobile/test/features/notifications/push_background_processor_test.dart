import 'package:feature_notifications/src/data/push_background_pending_store.dart';
import 'package:feature_notifications/src/data/push_background_processor.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/fake_flutter_local_notifications_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PushBackgroundPendingStore.clearForTest();
    resetBackgroundLocalNotificationsForTest();
    FlutterLocalNotificationsPlatform.instance =
        FakeFlutterLocalNotificationsPlatform();
  });

  test('processBackgroundPushMessage records pending inbox bump', () async {
    await processBackgroundPushMessage(
      const RemoteMessage(
        messageId: 'bg-1',
        data: <String, String>{
          'type': 'COMMENT',
          'notificationId': 'n-bg-1',
          'unreadCount': '2',
        },
      ),
    );

    final PendingPushDrainResult pending =
        await PushBackgroundPendingStore.drainPending();
    expect(pending.inboxBump, isTrue);
    expect(pending.unreadCount, 2);
    expect(pending.tapPayload?['notificationId'], 'n-bg-1');
  });

  test(
    'processBackgroundPushMessage handles EVENT_CHAT without throwing',
    () async {
      await processBackgroundPushMessage(
        const RemoteMessage(
          messageId: 'bg-chat-1',
          data: <String, String>{
            'type': 'EVENT_CHAT',
            'title': 'Cleanup chat',
            'messagePreview': 'On my way',
            'eventId': 'evt-1',
            'notificationId': 'notif-chat-1',
            'unreadCount': '1',
          },
        ),
      );

      final PendingPushDrainResult pending =
          await PushBackgroundPendingStore.drainPending();
      expect(pending.inboxBump, isTrue);
      expect(pending.unreadCount, 1);
      expect(pending.tapPayload?['type'], 'EVENT_CHAT');
    },
  );

  test(
    'processBackgroundPushMessage skips badge when unread missing',
    () async {
      await processBackgroundPushMessage(
        const RemoteMessage(
          messageId: 'bg-no-unread',
          data: <String, String>{
            'type': 'COMMENT',
            'title': 'Hi',
            'body': 'There',
          },
        ),
      );

      final PendingPushDrainResult pending =
          await PushBackgroundPendingStore.drainPending();
      expect(pending.unreadCount, isNull);
      expect(pending.inboxBump, isTrue);
    },
  );

  test(
    'processBackgroundPushMessage is idempotent for local notification init',
    () async {
      const RemoteMessage chatMessage = RemoteMessage(
        messageId: 'bg-chat-2',
        data: <String, String>{
          'type': 'EVENT_CHAT',
          'title': 'Chat',
          'messagePreview': 'Ping',
        },
      );

      await processBackgroundPushMessage(chatMessage);
      resetBackgroundLocalNotificationsForTest();
      FlutterLocalNotificationsPlatform.instance =
          FakeFlutterLocalNotificationsPlatform();

      await expectLater(processBackgroundPushMessage(chatMessage), completes);
    },
  );
}
