import 'package:chisto_mobile/features/notifications/domain/models/user_notification.dart';

class NotificationSectionGroup {
  const NotificationSectionGroup({required this.title, required this.items});

  final String title;
  final List<UserNotification> items;
}

List<NotificationSectionGroup> groupNotificationsByDay(
  List<UserNotification> notifications, {
  DateTime? now,
}) {
  final DateTime refNow = now ?? DateTime.now();
  final List<UserNotification> ordered = List<UserNotification>.from(
    notifications,
  )..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final List<NotificationSectionGroup> sections = <NotificationSectionGroup>[];
  String? currentLabel;
  List<UserNotification> bucket = <UserNotification>[];
  for (final UserNotification item in ordered) {
    final String label = notificationDayLabel(item.createdAt, now: refNow);
    currentLabel ??= label;
    if (label != currentLabel) {
      sections.add(
        NotificationSectionGroup(title: currentLabel, items: bucket),
      );
      currentLabel = label;
      bucket = <UserNotification>[];
    }
    bucket.add(item);
  }
  if (currentLabel != null && bucket.isNotEmpty) {
    sections.add(NotificationSectionGroup(title: currentLabel, items: bucket));
  }
  return sections;
}

String notificationDayLabel(DateTime value, {DateTime? now}) {
  final DateTime refNow = now ?? DateTime.now();
  final DateTime today = DateTime(refNow.year, refNow.month, refNow.day);
  final DateTime input = DateTime(value.year, value.month, value.day);
  final int diff = today.difference(input).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
}
