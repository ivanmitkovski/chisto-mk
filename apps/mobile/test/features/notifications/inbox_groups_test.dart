import 'package:feature_notifications/src/domain/inbox_groups.dart';
import 'package:feature_notifications/src/domain/models/notification_actor.dart';
import 'package:feature_notifications/src/domain/models/user_notification.dart';
import 'package:flutter_test/flutter_test.dart';

UserNotification _item({
  required String id,
  required UserNotificationType type,
  required DateTime createdAt,
  String? groupKey,
  NotificationActor? actor,
  bool isRead = false,
}) {
  return UserNotification(
    id: id,
    title: 'Title $id',
    body: 'Body $id',
    type: type,
    isRead: isRead,
    createdAt: createdAt,
    groupKey: groupKey,
    data: groupKey != null ? <String, dynamic>{'siteId': 's1'} : null,
    actor: actor,
  );
}

void main() {
  test('groups same groupKey within 24h and aggregates actors', () {
    final DateTime at = DateTime(2026, 3, 27, 12, 0);
    final List<UserNotification> items = <UserNotification>[
      _item(
        id: '1',
        type: UserNotificationType.upvote,
        createdAt: at,
        groupKey: 'UPVOTE:site:s1',
        actor: const NotificationActor(id: 'a1', displayName: 'Ana'),
      ),
      _item(
        id: '2',
        type: UserNotificationType.upvote,
        createdAt: at.subtract(const Duration(minutes: 5)),
        groupKey: 'UPVOTE:site:s1',
        actor: const NotificationActor(id: 'a2', displayName: 'Bojan'),
        isRead: true,
      ),
    ];

    final List<InboxDaySection> sections = groupInboxNotifications(
      items,
      dayTitleFor: (_) => 'Today',
      now: at,
    );

    expect(sections, hasLength(1));
    expect(sections.first.groups, hasLength(1));
    final InboxNotificationGroup group = sections.first.groups.first;
    expect(group.isGrouped, isTrue);
    expect(group.items, hasLength(2));
    expect(group.unreadCount, 1);
    expect(group.topActors.map((a) => a.id), <String>['a1', 'a2']);
  });

  test('groups event chat rows by groupKey within 24h', () {
    final DateTime at = DateTime(2026, 3, 27, 12, 0);
    final List<UserNotification> chats = <UserNotification>[
      UserNotification(
        id: 'c1',
        title: 'Clean it',
        body: 'Ana: hi',
        type: UserNotificationType.eventChat,
        isRead: false,
        createdAt: at,
        groupKey: 'event-chat:e1',
        data: const <String, dynamic>{'eventId': 'e1'},
        actor: const NotificationActor(id: 'a1', displayName: 'Ana'),
      ),
      UserNotification(
        id: 'c2',
        title: 'Clean it',
        body: 'Ana: earlier',
        type: UserNotificationType.eventChat,
        isRead: false,
        createdAt: at.subtract(const Duration(seconds: 1)),
        groupKey: 'event-chat:e1',
        data: const <String, dynamic>{'eventId': 'e1'},
        actor: const NotificationActor(id: 'a1', displayName: 'Ana'),
      ),
    ];
    final List<InboxDaySection> sections = groupInboxNotifications(
      chats,
      dayTitleFor: (_) => 'Today',
      now: at,
    );
    expect(sections.first.groups, hasLength(1));
    final InboxNotificationGroup group = sections.first.groups.first;
    expect(group.isGrouped, isTrue);
    expect(group.items, hasLength(2));
    expect(group.unreadCount, 2);
  });

  test('does not group system notifications', () {
    final DateTime at = DateTime(2026, 3, 27, 12, 0);
    final List<UserNotification> items = <UserNotification>[
      _item(
        id: 's1',
        type: UserNotificationType.system,
        createdAt: at,
        groupKey: 'SYSTEM:x',
      ),
      _item(
        id: 's2',
        type: UserNotificationType.system,
        createdAt: at.subtract(const Duration(minutes: 1)),
        groupKey: 'SYSTEM:x',
      ),
    ];
    final List<InboxDaySection> sections = groupInboxNotifications(
      items,
      dayTitleFor: (_) => 'Today',
      now: at,
    );
    expect(sections.first.groups, hasLength(2));
  });
}
