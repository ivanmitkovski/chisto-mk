import 'package:chisto_mobile/features/notifications/domain/models/user_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserNotification parsing', () {
    test('maps known notification types and payload fields', () {
      final model = UserNotification.fromJson(<String, dynamic>{
        'id': 'n1',
        'title': 'New upvote',
        'body': 'Your report received support',
        'type': 'UPVOTE',
        'isRead': false,
        'createdAt': '2026-03-27T10:00:00.000Z',
        'sentAt': '2026-03-27T10:00:01.000Z',
        'data': <String, dynamic>{'siteId': 'site_1', 'targetTab': '0'},
      });

      expect(model.type, UserNotificationType.upvote);
      expect(model.targetSiteId, 'site_1');
      expect(model.targetTab, '0');
      expect(model.isRead, isFalse);
    });

    test('falls back to system type for unknown values', () {
      final model = UserNotification.fromJson(<String, dynamic>{
        'id': 'n2',
        'title': 'Unknown',
        'body': 'Body',
        'type': 'SOMETHING_NEW',
        'isRead': true,
        'createdAt': '2026-03-27T10:00:00.000Z',
      });

      expect(model.type, UserNotificationType.system);
      expect(model.sentAt, isNull);
      expect(model.data, isNull);
    });

    test('parses thread and group metadata fields', () {
      final model = UserNotification.fromJson(<String, dynamic>{
        'id': 'n3',
        'title': 'Grouped',
        'body': 'Body',
        'type': 'COMMENT',
        'isRead': false,
        'createdAt': '2026-03-27T10:00:00.000Z',
        'threadKey': 'site:abc',
        'groupKey': 'COMMENT:site:abc',
      });

      expect(model.threadKey, 'site:abc');
      expect(model.groupKey, 'COMMENT:site:abc');
      expect(
        toNotificationTypeApiValue(UserNotificationType.comment),
        'COMMENT',
      );
    });
  });
}
