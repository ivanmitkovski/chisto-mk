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
        'data': <String, dynamic>{
          'siteId': 'site_1',
          'targetTab': '0',
          'targetAction': 'show_upvoters',
        },
      });

      expect(model.type, UserNotificationType.upvote);
      expect(model.targetSiteId, 'site_1');
      expect(model.targetTab, '0');
      expect(model.targetAction, 'show_upvoters');
      expect(model.highlightActorUserId, isNull);
      expect(model.isRead, isFalse);
    });

    test('parses highlight payload fields', () {
      final model = UserNotification.fromJson(<String, dynamic>{
        'id': 'n4',
        'title': 'Comment',
        'body': 'Body',
        'type': 'COMMENT',
        'isRead': false,
        'createdAt': '2026-03-27T10:00:00.000Z',
        'data': <String, dynamic>{
          'siteId': 'site_1',
          'actorUserId': 'actor_1',
          'commentId': 'comment_1',
        },
      });

      expect(model.highlightActorUserId, 'actor_1');
      expect(model.highlightCommentId, 'comment_1');
    });

    test('parses actor enrichment from API', () {
      final model = UserNotification.fromJson(<String, dynamic>{
        'id': 'n5',
        'title': 'Upvote',
        'body': 'Body',
        'type': 'UPVOTE',
        'isRead': false,
        'createdAt': '2026-03-27T10:00:00.000Z',
        'actor': <String, dynamic>{
          'id': 'actor_1',
          'displayName': 'Ana K',
          'avatarUrl': 'https://cdn.test/a.jpg',
        },
      });

      expect(model.actor?.id, 'actor_1');
      expect(model.actor?.displayName, 'Ana K');
      expect(model.actor?.avatarUrl, 'https://cdn.test/a.jpg');
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
