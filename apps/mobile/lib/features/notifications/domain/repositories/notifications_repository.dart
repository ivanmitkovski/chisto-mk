import 'package:chisto_mobile/features/notifications/domain/models/user_notification.dart';

class NotificationsListResult {
  const NotificationsListResult({
    required this.notifications,
    required this.total,
    required this.unreadCount,
    required this.page,
    required this.limit,
  });

  final List<UserNotification> notifications;
  final int total;
  final int unreadCount;
  final int page;
  final int limit;
}

abstract class NotificationsRepository {
  Future<NotificationsListResult> getNotifications({
    int page = 1,
    int limit = 20,
    bool onlyUnread = false,
  });

  Future<int> getUnreadCount();

  Future<void> markAsRead(String notificationId);

  Future<void> markAllAsRead();

  Future<List<NotificationPreference>> getPreferences();

  Future<NotificationPreference> setPreference({
    required UserNotificationType type,
    required bool muted,
    DateTime? mutedUntil,
  });

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? appVersion,
    String? locale,
  });

  Future<void> unregisterDeviceToken(String token);

  Future<void> markAsUnread(String notificationId);

  Future<void> archiveNotification(String notificationId);

  Future<void> archiveAllRead();
}
