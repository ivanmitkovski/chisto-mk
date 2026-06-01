import 'package:feature_notifications/src/domain/models/notification_actor.dart';
import 'package:feature_notifications/src/domain/models/user_notification.dart';
import 'package:feature_notifications/src/domain/notifications_grouping.dart';

/// One visual row in the inbox (single notification or a collapsible stack).
class InboxNotificationGroup {
  const InboxNotificationGroup({
    required this.key,
    required this.items,
    required this.representative,
    required this.topActors,
    required this.totalActorCount,
    required this.unreadCount,
  });

  final String key;
  final List<UserNotification> items;
  final UserNotification representative;
  final List<NotificationActor> topActors;
  final int totalActorCount;
  final int unreadCount;

  bool get isGrouped => items.length > 1;

  DateTime get latestAt => representative.createdAt;
}

class InboxDaySection {
  const InboxDaySection({
    required this.dayKey,
    required this.title,
    required this.groups,
  });

  final String dayKey;
  final String title;
  final List<InboxNotificationGroup> groups;
}

const Duration _kGroupWindow = Duration(hours: 24);

const Set<UserNotificationType> _kNeverGroupTypes = <UserNotificationType>{
  UserNotificationType.system,
  UserNotificationType.welcome,
  UserNotificationType.achievement,
};

bool _shouldNeverGroup(UserNotificationType type) =>
    _kNeverGroupTypes.contains(type);

String _groupingKey(UserNotification item) {
  if (_shouldNeverGroup(item.type)) {
    return 'single:${item.id}';
  }
  if (item.type == UserNotificationType.eventChat) {
    return 'event-chat:${item.targetEventId ?? item.id}';
  }
  final String? gk = item.groupKey?.trim();
  if (gk != null && gk.isNotEmpty) return gk;
  final String? siteId = item.targetSiteId;
  if (siteId != null && siteId.isNotEmpty) {
    return '${item.type.name}:site:$siteId';
  }
  final String? eventId = item.targetEventId;
  if (eventId != null && eventId.isNotEmpty) {
    return '${item.type.name}:event:$eventId';
  }
  return 'single:${item.id}';
}

bool _canMergeIntoGroup(UserNotification current, UserNotification next) {
  if (_shouldNeverGroup(current.type) || _shouldNeverGroup(next.type)) {
    return false;
  }
  if (_groupingKey(current) != _groupingKey(next)) return false;
  return current.createdAt.difference(next.createdAt).abs() < _kGroupWindow;
}

List<NotificationActor> _collectTopActors(List<UserNotification> items) {
  final List<NotificationActor> actors = <NotificationActor>[];
  final Set<String> seen = <String>{};
  for (final UserNotification item in items) {
    final NotificationActor? actor = item.actor;
    if (actor == null || actor.id.isEmpty) continue;
    if (seen.add(actor.id)) {
      actors.add(actor);
    }
    if (actors.length >= 3) break;
  }
  return actors;
}

int _countDistinctActors(List<UserNotification> items) {
  final Set<String> ids = <String>{};
  for (final UserNotification item in items) {
    final NotificationActor? actor = item.actor;
    if (actor != null && actor.id.isNotEmpty) {
      ids.add(actor.id);
    }
  }
  return ids.length;
}

List<InboxNotificationGroup> _buildGroupsForDay(
  List<UserNotification> dayItems,
) {
  if (dayItems.isEmpty) return <InboxNotificationGroup>[];
  final List<UserNotification> ordered = List<UserNotification>.from(dayItems)
    ..sort(
      (UserNotification a, UserNotification b) =>
          b.createdAt.compareTo(a.createdAt),
    );

  final List<InboxNotificationGroup> groups = <InboxNotificationGroup>[];
  List<UserNotification> bucket = <UserNotification>[ordered.first];

  for (int i = 1; i < ordered.length; i++) {
    final UserNotification item = ordered[i];
    final UserNotification head = bucket.first;
    if (_canMergeIntoGroup(head, item)) {
      bucket.add(item);
    } else {
      groups.add(_finalizeGroup(bucket));
      bucket = <UserNotification>[item];
    }
  }
  groups.add(_finalizeGroup(bucket));
  return groups;
}

InboxNotificationGroup _finalizeGroup(List<UserNotification> bucket) {
  final UserNotification rep = bucket.first;
  final List<NotificationActor> topActors = _collectTopActors(bucket);
  final int actorCount = _countDistinctActors(bucket);
  final int unread = bucket.where((UserNotification n) => !n.isRead).length;
  final int displayCount = notificationDisplayCount(
    rep,
    collapsedRows: bucket.length,
  );
  return InboxNotificationGroup(
    key: _groupingKey(rep),
    items: List<UserNotification>.from(bucket),
    representative: rep,
    topActors: topActors,
    totalActorCount: actorCount > 0 ? actorCount : displayCount,
    unreadCount: unread,
  );
}

/// Day sections with inline-expandable notification groups.
List<InboxDaySection> groupInboxNotifications(
  List<UserNotification> notifications, {
  required String Function(DateTime createdAt) dayTitleFor,
  DateTime? now,
}) {
  final List<NotificationSectionGroup> days = groupNotificationsByDay(
    notifications,
    now: now,
  );
  return days
      .map((NotificationSectionGroup section) {
        final DateTime anchor = section.items.isNotEmpty
            ? section.items.first.createdAt
            : (now ?? DateTime.now());
        return InboxDaySection(
          dayKey: section.title,
          title: dayTitleFor(anchor),
          groups: _buildGroupsForDay(section.items),
        );
      })
      .toList(growable: false);
}
