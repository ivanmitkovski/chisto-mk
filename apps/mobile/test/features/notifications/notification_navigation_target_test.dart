import 'package:feature_notifications/src/data/notification_navigation_target.dart';
import 'package:feature_notifications/src/domain/models/user_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveNotificationNavigationTarget', () {
    test('report_received prefers reportId over siteId', () {
      final NotificationNavigationTarget target =
          resolveNotificationNavigationTarget(
            type: 'SYSTEM',
            data: <String, dynamic>{
              'kind': 'report_received',
              'reportId': 'report_073',
              'siteId': 'site_shared',
            },
          );
      expect(target, isA<NotificationOpenReportDetail>());
      expect(
        (target as NotificationOpenReportDetail).reportId,
        'report_073',
      );
    });

    test('SYSTEM with reportId routes to report detail even when kind is lost', () {
      final NotificationNavigationTarget target =
          resolveNotificationNavigationTarget(
            type: 'SYSTEM',
            data: <String, dynamic>{
              'kind': 'digest_deferred',
              'reportId': 'report_073',
              'siteId': 'site_shared',
            },
          );
      expect(target, isA<NotificationOpenReportDetail>());
      expect(
        (target as NotificationOpenReportDetail).reportId,
        'report_073',
      );
    });

    test('REPORT_STATUS with reportId opens report detail', () {
      final NotificationNavigationTarget target =
          resolveNotificationNavigationTarget(
            type: 'REPORT_STATUS',
            data: <String, dynamic>{
              'reportId': 'report_abc',
              'siteId': 'site_1',
            },
          );
      expect(target, isA<NotificationOpenReportDetail>());
      expect(
        (target as NotificationOpenReportDetail).reportId,
        'report_abc',
      );
    });

    test('REPORT_STATUS with siteId only opens site detail', () {
      final NotificationNavigationTarget target =
          resolveNotificationNavigationTarget(
            type: 'REPORT_STATUS',
            data: <String, dynamic>{'siteId': 'site_1'},
          );
      expect(target, isA<NotificationOpenSiteDetail>());
      expect((target as NotificationOpenSiteDetail).siteId, 'site_1');
    });

    test('CLEANUP_EVENT with siteId and eventId opens event detail', () {
      const String eventId = '550e8400-e29b-41d4-a716-446655440000';
      final NotificationNavigationTarget target =
          resolveNotificationNavigationTarget(
            type: 'CLEANUP_EVENT',
            data: <String, dynamic>{
              'eventId': eventId,
              'siteId': 'site_1',
            },
          );
      expect(target, isA<NotificationOpenEventDetail>());
      expect((target as NotificationOpenEventDetail).eventId, eventId);
    });

    test('CLEANUP_EVENT cuid event id is accepted', () {
      const String eventId = 'c1234567890abcdefghijklmn';
      final NotificationNavigationTarget target =
          resolveNotificationNavigationTarget(
            type: 'CLEANUP_EVENT',
            data: <String, dynamic>{'eventId': eventId},
          );
      expect(target, isA<NotificationOpenEventDetail>());
    });

    test('COMMENT passes targetAction and highlight ids', () {
      final NotificationNavigationTarget target =
          resolveNotificationNavigationTarget(
            type: 'COMMENT',
            data: <String, dynamic>{
              'siteId': 'site_1',
              'commentId': 'comment_1',
              'actorUserId': 'user_1',
              'targetAction': 'show_comments',
              'targetTab': '1',
            },
          );
      expect(target, isA<NotificationOpenSiteDetail>());
      final NotificationOpenSiteDetail site =
          target as NotificationOpenSiteDetail;
      expect(site.initialAction, 'show_comments');
      expect(site.initialTabIndex, 1);
      expect(site.initialHighlight?.commentId, 'comment_1');
    });

    test('ACHIEVEMENT opens profile achievements', () {
      final NotificationNavigationTarget target =
          resolveNotificationNavigationTarget(
            type: 'ACHIEVEMENT',
            data: const <String, dynamic>{},
          );
      expect(target, isA<NotificationOpenProfileAchievements>());
    });

    test('WELCOME opens feature guide', () {
      final NotificationNavigationTarget target =
          resolveNotificationNavigationTarget(
            type: 'WELCOME',
            data: const <String, dynamic>{},
          );
      expect(target, isA<NotificationOpenFeatureGuide>());
    });

    test('SYSTEM test_push is informational only', () {
      final NotificationNavigationTarget target =
          resolveNotificationNavigationTarget(
            type: 'SYSTEM',
            data: const <String, dynamic>{'kind': 'test_push'},
          );
      expect(target, isA<NotificationOpenInformational>());
    });

    test('SYSTEM admin_broadcast without deeplink is informational only', () {
      final NotificationNavigationTarget target =
          resolveNotificationNavigationTarget(
            type: 'SYSTEM',
            data: const <String, dynamic>{'kind': 'admin_broadcast'},
          );
      expect(target, isA<NotificationOpenInformational>());
    });

    test('SYSTEM admin_broadcast with deeplink opens deep link', () {
      final NotificationNavigationTarget target =
          resolveNotificationNavigationTarget(
            type: 'SYSTEM',
            data: const <String, dynamic>{
              'kind': 'admin_broadcast',
              'deeplink': '/app/home?tab=events',
            },
          );
      expect(target, isA<NotificationOpenDeepLink>());
      expect(
        (target as NotificationOpenDeepLink).path,
        '/app/home?tab=events',
      );
    });

    test('SYSTEM without entity ids is informational only', () {
      final NotificationNavigationTarget target =
          resolveNotificationNavigationTarget(
            type: 'SYSTEM',
            data: const <String, dynamic>{},
          );
      expect(target, isA<NotificationOpenInformational>());
    });

    test('unknown type returns unsupported failure', () {
      final NotificationNavigationTarget target =
          resolveNotificationNavigationTarget(
            type: 'MYSTERY',
            data: const <String, dynamic>{},
          );
      expect(target, isA<NotificationOpenFailure>());
      expect(
        (target as NotificationOpenFailure).reason,
        NotificationOpenFailureReason.unsupportedType,
      );
    });
  });

  group('resolveNotificationNavigationTargetFromItem', () {
    test('maps SYSTEM report_received inbox row to report detail', () {
      final UserNotification item = UserNotification(
        id: 'n1',
        title: 'We received CH-000073',
        body: 'Thanks',
        type: UserNotificationType.system,
        isRead: false,
        createdAt: DateTime.utc(2026, 6, 9),
        data: <String, dynamic>{
          'kind': 'report_received',
          'reportId': 'report_073',
          'siteId': 'site_shared',
        },
      );
      final NotificationNavigationTarget target =
          resolveNotificationNavigationTargetFromItem(item);
      expect(target, isA<NotificationOpenReportDetail>());
      expect(
        (target as NotificationOpenReportDetail).reportId,
        'report_073',
      );
    });

    test('same site different report ids resolve to distinct targets', () {
      final UserNotification older = UserNotification(
        id: 'n1',
        title: 'We received CH-000072',
        body: 'Thanks',
        type: UserNotificationType.system,
        isRead: false,
        createdAt: DateTime.utc(2026, 6, 8),
        data: <String, dynamic>{
          'kind': 'report_received',
          'reportId': 'report_072',
          'siteId': 'site_shared',
        },
      );
      final UserNotification newer = UserNotification(
        id: 'n2',
        title: 'We received CH-000073',
        body: 'Thanks',
        type: UserNotificationType.system,
        isRead: false,
        createdAt: DateTime.utc(2026, 6, 9),
        data: <String, dynamic>{
          'kind': 'report_received',
          'reportId': 'report_073',
          'siteId': 'site_shared',
        },
      );
      final NotificationOpenReportDetail olderTarget =
          resolveNotificationNavigationTargetFromItem(older)
              as NotificationOpenReportDetail;
      final NotificationOpenReportDetail newerTarget =
          resolveNotificationNavigationTargetFromItem(newer)
              as NotificationOpenReportDetail;
      expect(olderTarget.reportId, isNot(newerTarget.reportId));
    });
  });

  group('UserNotification.targetReportId', () {
    test('reads reportId from data payload', () {
      final UserNotification item = UserNotification(
        id: 'n1',
        title: 'Report',
        body: 'Body',
        type: UserNotificationType.reportStatus,
        isRead: false,
        createdAt: DateTime.utc(2026, 6, 9),
        data: <String, dynamic>{'reportId': 'report_xyz'},
      );
      expect(item.targetReportId, 'report_xyz');
    });
  });
}
