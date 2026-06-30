import 'package:feature_notifications/src/domain/models/user_notification.dart';
import 'package:feature_notifications/src/domain/notifications_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('groups notifications by day in descending order', () {
    final DateTime now = DateTime(2026, 3, 27, 12, 0);
    final List<UserNotification> notifications = <UserNotification>[
      UserNotification(
        id: 'a',
        title: 'Newest',
        body: 'body',
        type: UserNotificationType.comment,
        isRead: false,
        createdAt: DateTime(2026, 3, 27, 11, 0),
      ),
      UserNotification(
        id: 'b',
        title: 'Yesterday',
        body: 'body',
        type: UserNotificationType.upvote,
        isRead: false,
        createdAt: DateTime(2026, 3, 26, 15, 0),
      ),
      UserNotification(
        id: 'c',
        title: 'Older',
        body: 'body',
        type: UserNotificationType.system,
        isRead: true,
        createdAt: DateTime(2026, 3, 20, 9, 0),
      ),
    ];

    final List<NotificationSectionGroup> grouped = groupNotificationsByDay(
      notifications,
      now: now,
    );

    expect(grouped.map((g) => g.title).toList(), <String>[
      'Today',
      'Yesterday',
      '20.03.2026',
    ]);
    expect(grouped.first.items.first.id, 'a');
  });

  test('collapseByGroupKey merges EVENT_CHAT rows with same groupKey', () {
    final DateTime at = DateTime(2026, 3, 27, 12, 0);
    final List<UserNotification> chats = <UserNotification>[
      UserNotification(
        id: 'chat-1',
        title: 'Cleanup',
        body: 'Alex: one',
        type: UserNotificationType.eventChat,
        isRead: false,
        createdAt: at,
        groupKey: 'event-chat:evt1',
      ),
      UserNotification(
        id: 'chat-2',
        title: 'Cleanup',
        body: 'Alex: two',
        type: UserNotificationType.eventChat,
        isRead: false,
        createdAt: at.subtract(const Duration(seconds: 1)),
        groupKey: 'event-chat:evt1',
      ),
    ];
    final List<CollapsedNotification> collapsed = collapseByGroupKey(chats);
    expect(collapsed.length, 1);
    expect(collapsed.first.groupCount, 2);
    expect(collapsed.first.representative.id, 'chat-1');
  });
}
