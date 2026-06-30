import 'package:feature_notifications/src/data/push_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveNotificationTitleBodyForTest', () {
    test('uses notification block when present', () {
      const RemoteMessage message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Site update',
          body: 'A site you follow changed.',
        ),
        data: <String, dynamic>{'type': 'SITE_UPDATE'},
      );
      final ({String? title, String? body}) resolved =
          PushNotificationService.resolveNotificationTitleBodyForTest(message);
      expect(resolved.title, 'Site update');
      expect(resolved.body, 'A site you follow changed.');
    });

    test('falls back to data title and body', () {
      const RemoteMessage message = RemoteMessage(
        data: <String, dynamic>{
          'type': 'COMMENT',
          'title': 'New comment',
          'body': 'Someone commented on your site.',
        },
      );
      final ({String? title, String? body}) resolved =
          PushNotificationService.resolveNotificationTitleBodyForTest(message);
      expect(resolved.title, 'New comment');
      expect(resolved.body, 'Someone commented on your site.');
    });

    test('EVENT_CHAT prefers messagePreview for body', () {
      const RemoteMessage message = RemoteMessage(
        data: <String, dynamic>{
          'type': 'EVENT_CHAT',
          'title': 'Event chat',
          'messagePreview': 'Hello volunteers',
          'body': 'ignored fallback',
        },
      );
      final ({String? title, String? body}) resolved =
          PushNotificationService.resolveNotificationTitleBodyForTest(message);
      expect(resolved.title, 'Event chat');
      expect(resolved.body, 'Hello volunteers');
    });

    test('notification block takes precedence over data', () {
      const RemoteMessage message = RemoteMessage(
        notification: RemoteNotification(
          title: 'From APNS',
          body: 'Alert body',
        ),
        data: <String, dynamic>{'title': 'From data', 'body': 'Data body'},
      );
      final ({String? title, String? body}) resolved =
          PushNotificationService.resolveNotificationTitleBodyForTest(message);
      expect(resolved.title, 'From APNS');
      expect(resolved.body, 'Alert body');
    });
  });
}
