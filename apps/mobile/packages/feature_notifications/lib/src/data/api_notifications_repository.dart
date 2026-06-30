import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/serialization/safe_json.dart';
import 'package:feature_notifications/src/domain/models/user_notification.dart';
import 'package:feature_notifications/src/domain/repositories/notifications_repository.dart';

class ApiNotificationsRepository implements NotificationsRepository {
  ApiNotificationsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  @override
  Future<NotificationsListResult> getNotifications({
    int page = 1,
    int limit = 20,
    bool onlyUnread = false,
  }) async {
    final String query =
        '?page=$page&limit=$limit${onlyUnread ? '&onlyUnread=true' : ''}';
    final ApiResponse response = await _client.get('/notifications$query');
    final Map<String, dynamic> json = response.json!;
    final List<dynamic> data = safeAsList(json['data']) ?? const <dynamic>[];
    final Map<String, dynamic>? meta = safeAsStringKeyedMap(json['meta']);

    final List<UserNotification> notifications = data
        .whereType<Map<String, dynamic>>()
        .map(UserNotification.fromJson)
        .toList();
    return NotificationsListResult(
      notifications: notifications,
      total: (meta?['total'] as num?)?.toInt() ?? notifications.length,
      unreadCount: (meta?['unreadCount'] as num?)?.toInt() ?? 0,
      page: (meta?['page'] as num?)?.toInt() ?? page,
      limit: (meta?['limit'] as num?)?.toInt() ?? limit,
    );
  }

  @override
  Future<int> getUnreadCount() async {
    final ApiResponse response = await _client.get(
      '/notifications/unread-count',
    );
    final Map<String, dynamic> json = response.json!;
    return (json['unreadCount'] as num).toInt();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _client.patch('/notifications/$notificationId/read');
  }

  @override
  Future<void> recordOpened(String notificationId) async {
    await _client.post('/notifications/$notificationId/opened');
  }

  @override
  Future<void> markAllAsRead() async {
    await _client.patch('/notifications/read-all');
  }

  @override
  Future<List<NotificationPreference>> getPreferences() async {
    final ApiResponse response = await _client.get(
      '/notifications/preferences',
    );
    final Map<String, dynamic> json = response.json!;
    final List<dynamic> data = safeAsList(json['data']) ?? <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(NotificationPreference.fromJson)
        .toList();
  }

  @override
  Future<NotificationPreference> setPreference({
    required UserNotificationType type,
    required bool muted,
    DateTime? mutedUntil,
  }) async {
    final String typeValue = toNotificationTypeApiValue(type);
    final ApiResponse response = await _client.patch(
      '/notifications/preferences/$typeValue',
      body: <String, dynamic>{
        'muted': muted,
        if (mutedUntil != null) 'mutedUntil': mutedUntil.toIso8601String(),
      },
    );
    return NotificationPreference.fromJson(response.json!);
  }

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? appVersion,
    String? locale,
  }) async {
    await _client.post(
      '/notifications/devices',
      body: <String, dynamic>{
        'token': token,
        'platform': platform,
        ...(appVersion != null ? {'appVersion': appVersion} : {}),
        ...(locale != null ? {'locale': locale} : {}),
      },
    );
  }

  @override
  Future<void> unregisterDeviceToken(String token) async {
    await _client.post(
      '/notifications/devices/unregister',
      body: <String, dynamic>{'token': token},
    );
  }

  @override
  Future<void> markAsUnread(String notificationId) async {
    await _client.patch('/notifications/$notificationId/unread');
  }

  @override
  Future<void> archiveNotification(String notificationId) async {
    await _client.patch('/notifications/$notificationId/archive');
  }

  @override
  Future<void> archiveAllRead() async {
    await _client.patch('/notifications/archive-all-read');
  }
}
