import 'package:chisto_mobile/features/notifications/domain/models/user_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserNotificationType', () {
    test('has expected enum values', () {
      expect(UserNotificationType.values.length, 10);
      expect(UserNotificationType.values, contains(UserNotificationType.siteUpdate));
      expect(UserNotificationType.values, contains(UserNotificationType.reportStatus));
      expect(UserNotificationType.values, contains(UserNotificationType.upvote));
      expect(UserNotificationType.values, contains(UserNotificationType.comment));
      expect(UserNotificationType.values, contains(UserNotificationType.nearbyReport));
      expect(UserNotificationType.values, contains(UserNotificationType.cleanupEvent));
      expect(UserNotificationType.values, contains(UserNotificationType.eventChat));
      expect(UserNotificationType.values, contains(UserNotificationType.system));
      expect(UserNotificationType.values, contains(UserNotificationType.achievement));
      expect(UserNotificationType.values, contains(UserNotificationType.welcome));
    });
  });

  group('parseNotificationType', () {
    test('parses known types', () {
      expect(parseNotificationType('SITE_UPDATE'), UserNotificationType.siteUpdate);
      expect(parseNotificationType('REPORT_STATUS'), UserNotificationType.reportStatus);
      expect(parseNotificationType('UPVOTE'), UserNotificationType.upvote);
      expect(parseNotificationType('COMMENT'), UserNotificationType.comment);
      expect(parseNotificationType('NEARBY_REPORT'), UserNotificationType.nearbyReport);
      expect(parseNotificationType('CLEANUP_EVENT'), UserNotificationType.cleanupEvent);
      expect(parseNotificationType('EVENT_CHAT'), UserNotificationType.eventChat);
      expect(parseNotificationType('SYSTEM'), UserNotificationType.system);
      expect(parseNotificationType('ACHIEVEMENT'), UserNotificationType.achievement);
      expect(parseNotificationType('WELCOME'), UserNotificationType.welcome);
    });

    test('defaults to system for unknown', () {
      expect(parseNotificationType('UNKNOWN'), UserNotificationType.system);
      expect(parseNotificationType(null), UserNotificationType.system);
    });
  });

  group('UserNotification', () {
    final DateTime createdAt = DateTime(2026, 5, 11, 10, 30);

    test('constructs with required fields', () {
      final UserNotification notification = UserNotification(
        id: 'n1',
        title: 'Update',
        body: 'Your report was reviewed',
        createdAt: createdAt,
        type: UserNotificationType.siteUpdate,
      );

      expect(notification.id, 'n1');
      expect(notification.title, 'Update');
      expect(notification.body, 'Your report was reviewed');
      expect(notification.createdAt, createdAt);
      expect(notification.type, UserNotificationType.siteUpdate);
      expect(notification.isRead, false);
      expect(notification.targetSiteId, isNull);
      expect(notification.archivedAt, isNull);
    });

    test('parses from JSON', () {
      final UserNotification n = UserNotification.fromJson(<String, dynamic>{
        'id': 'n2',
        'title': 'Upvote',
        'body': 'Someone upvoted your report',
        'type': 'UPVOTE',
        'isRead': true,
        'createdAt': '2026-05-11T10:30:00.000Z',
        'data': <String, dynamic>{'siteId': 'site-1', 'targetTab': '0'},
        'archivedAt': '2026-05-11T11:00:00.000Z',
      });

      expect(n.type, UserNotificationType.upvote);
      expect(n.isRead, true);
      expect(n.targetSiteId, 'site-1');
      expect(n.targetTab, '0');
      expect(n.archivedAt, isNotNull);
    });

    test('copyWith produces new instance with updated fields', () {
      final UserNotification original = UserNotification(
        id: 'n1',
        title: 'Original',
        body: 'Original body',
        createdAt: createdAt,
        type: UserNotificationType.upvote,
        isRead: false,
      );

      final UserNotification updated = original.copyWith(isRead: true);

      expect(updated.id, 'n1');
      expect(updated.title, 'Original');
      expect(updated.isRead, true);
      expect(updated.type, UserNotificationType.upvote);
    });
  });
}
