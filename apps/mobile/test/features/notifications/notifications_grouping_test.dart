import 'package:chisto_mobile/features/notifications/domain/models/user_notification.dart';
import 'package:chisto_mobile/features/notifications/domain/notifications_grouping.dart';
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
}
