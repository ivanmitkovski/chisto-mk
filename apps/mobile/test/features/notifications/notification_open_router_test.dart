import 'package:feature_notifications/src/data/notification_navigation_target.dart';
import 'package:feature_notifications/src/domain/models/user_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('push and inbox routing parity', () {
    test(
      'report_received resolves to report detail from push data and inbox item',
      () {
        const Map<String, dynamic> data = <String, dynamic>{
          'type': 'SYSTEM',
          'kind': 'report_received',
          'reportId': 'report_073',
          'siteId': 'site_shared',
        };
        final NotificationNavigationTarget pushTarget =
            resolveNotificationNavigationTargetFromData(data);
        final UserNotification item = UserNotification(
          id: 'n1',
          title: 'We received CH-000073',
          body: 'Thanks',
          type: UserNotificationType.system,
          isRead: false,
          createdAt: DateTime.utc(2026, 6, 9),
          data: data,
        );
        final NotificationNavigationTarget inboxTarget =
            resolveNotificationNavigationTargetFromItem(item);

        expect(pushTarget, isA<NotificationOpenReportDetail>());
        expect(inboxTarget, isA<NotificationOpenReportDetail>());
        expect(
          (pushTarget as NotificationOpenReportDetail).reportId,
          (inboxTarget as NotificationOpenReportDetail).reportId,
        );
      },
    );

    test(
      'CLEANUP_EVENT with siteId resolves to event detail not map focus',
      () {
        const String eventId = '550e8400-e29b-41d4-a716-446655440000';
        final NotificationNavigationTarget target =
            resolveNotificationNavigationTargetFromData(<String, dynamic>{
              'type': 'CLEANUP_EVENT',
              'eventId': eventId,
              'siteId': 'site-abc',
            });
        expect(target, isA<NotificationOpenEventDetail>());
        expect(target, isNot(isA<NotificationOpenHomeMapFocus>()));
      },
    );

    test(
      'REPORT_STATUS with reportId resolves to report detail from push data',
      () {
        final NotificationNavigationTarget target =
            resolveNotificationNavigationTargetFromData(<String, dynamic>{
              'type': 'REPORT_STATUS',
              'reportId': 'report_abc',
              'siteId': 'site-abc',
            });
        expect(target, isA<NotificationOpenReportDetail>());
        expect((target as NotificationOpenReportDetail).reportId, 'report_abc');
      },
    );
  });
}
