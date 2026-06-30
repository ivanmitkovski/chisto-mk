import 'package:feature_notifications/src/data/notification_inbox_actions.dart';
import 'package:feature_notifications/src/data/notification_inbox_router.dart';
import 'package:feature_notifications/src/domain/models/notification_inbox_highlight.dart';
import 'package:feature_notifications/src/domain/models/user_notification.dart';
import 'package:flutter_test/flutter_test.dart';

UserNotification _notification({
  required UserNotificationType type,
  Map<String, dynamic>? data,
}) {
  return UserNotification(
    id: 'n1',
    title: 'Title',
    body: 'Body',
    type: type,
    isRead: false,
    createdAt: DateTime.utc(2026, 3, 27),
    data: data,
  );
}

void main() {
  group('NotificationInboxRouter.resolveHighlight', () {
    test('returns highlight for UPVOTE with actorUserId', () {
      final UserNotification item = _notification(
        type: UserNotificationType.upvote,
        data: <String, dynamic>{
          'siteId': 'site_1',
          'actorUserId': 'user_actor',
        },
      );
      final NotificationInboxHighlight? highlight =
          NotificationInboxRouter.resolveHighlight(item);
      expect(highlight, isNotNull);
      expect(highlight!.actorUserId, 'user_actor');
      expect(highlight.commentId, isNull);
    });

    test('returns highlight for COMMENT with commentId', () {
      final UserNotification item = _notification(
        type: UserNotificationType.comment,
        data: <String, dynamic>{
          'siteId': 'site_1',
          'commentId': 'comment_1',
          'actorUserId': 'user_actor',
        },
      );
      final NotificationInboxHighlight? highlight =
          NotificationInboxRouter.resolveHighlight(item);
      expect(highlight?.commentId, 'comment_1');
      expect(highlight?.actorUserId, 'user_actor');
    });

    test('returns null when no highlight ids', () {
      final UserNotification item = _notification(
        type: UserNotificationType.comment,
        data: <String, dynamic>{'siteId': 'site_1'},
      );
      expect(NotificationInboxRouter.resolveHighlight(item), isNull);
    });

    test('returns null for report status', () {
      final UserNotification item = _notification(
        type: UserNotificationType.reportStatus,
        data: <String, dynamic>{'siteId': 'site_1', 'actorUserId': 'u1'},
      );
      expect(NotificationInboxRouter.resolveHighlight(item), isNull);
    });

    test('targetReportId is exposed from data', () {
      final UserNotification item = _notification(
        type: UserNotificationType.system,
        data: <String, dynamic>{
          'kind': 'report_received',
          'reportId': 'report_073',
          'siteId': 'site_shared',
        },
      );
      expect(item.targetReportId, 'report_073');
    });
  });

  group('NotificationInboxRouter.resolveInitialAction', () {
    test('uses targetAction when present', () {
      final UserNotification item = _notification(
        type: UserNotificationType.comment,
        data: <String, dynamic>{
          'targetAction': NotificationInboxActions.showUpvoters,
        },
      );
      expect(
        NotificationInboxRouter.resolveInitialAction(item),
        NotificationInboxActions.showUpvoters,
      );
    });

    test('defaults UPVOTE to show_upvoters', () {
      final UserNotification item = _notification(
        type: UserNotificationType.upvote,
        data: <String, dynamic>{'siteId': 'site_1'},
      );
      expect(
        NotificationInboxRouter.resolveInitialAction(item),
        NotificationInboxActions.showUpvoters,
      );
    });

    test('defaults COMMENT to show_comments', () {
      final UserNotification item = _notification(
        type: UserNotificationType.comment,
        data: <String, dynamic>{'siteId': 'site_1'},
      );
      expect(
        NotificationInboxRouter.resolveInitialAction(item),
        NotificationInboxActions.showComments,
      );
    });

    test('returns null for site-only types without targetAction', () {
      final UserNotification item = _notification(
        type: UserNotificationType.reportStatus,
        data: <String, dynamic>{'siteId': 'site_1'},
      );
      expect(NotificationInboxRouter.resolveInitialAction(item), isNull);
    });
  });

  group('UserNotification deep-link getters', () {
    test('exposes event and action fields from data', () {
      final UserNotification item = UserNotification.fromJson(<String, dynamic>{
        'id': 'n1',
        'title': 'Chat',
        'body': 'New message',
        'type': 'EVENT_CHAT',
        'isRead': false,
        'createdAt': '2026-03-27T10:00:00.000Z',
        'data': <String, dynamic>{
          'eventId': 'evt_abc123456789012345678901',
          'threadTitle': 'Beach cleanup',
          'targetAction': 'show_comments',
          'kind': 'report_received',
        },
      });

      expect(item.targetEventId, 'evt_abc123456789012345678901');
      expect(item.targetAction, 'show_comments');
      expect(item.dataKind, 'report_received');
      expect(item.eventTitleFromData, 'Beach cleanup');
    });

    test('parses COMMENT payload with targetAction from API', () {
      final UserNotification item = UserNotification.fromJson(<String, dynamic>{
        'id': 'n2',
        'title': 'Comment',
        'body': 'Someone commented',
        'type': 'COMMENT',
        'isRead': false,
        'createdAt': '2026-03-27T10:00:00.000Z',
        'data': <String, dynamic>{
          'siteId': 'site_1',
          'targetTab': '0',
          'targetAction': 'show_comments',
          'messagePreview': 'Nice work',
        },
      });

      expect(item.targetAction, NotificationInboxActions.showComments);
      expect(
        NotificationInboxRouter.resolveInitialAction(item),
        NotificationInboxActions.showComments,
      );
    });
  });
}
