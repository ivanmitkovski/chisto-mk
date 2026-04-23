import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';

/// No-op platform for widget/unit tests: the real plugin never registers in the
/// test binding, so `FlutterLocalNotificationsPlatform.instance` would otherwise
/// throw on first access.
class FakeFlutterLocalNotificationsPlatform extends FlutterLocalNotificationsPlatform {
  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<List<ActiveNotification>> getActiveNotifications() async => const <ActiveNotification>[];

  @override
  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() async =>
      const NotificationAppLaunchDetails(false);

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async =>
      const <PendingNotificationRequest>[];

  @override
  Future<void> periodicallyShow(
    int id,
    String? title,
    String? body,
    RepeatInterval repeatInterval,
  ) async {}

  @override
  Future<void> periodicallyShowWithDuration(
    int id,
    String? title,
    String? body,
    Duration repeatDurationInterval,
  ) async {}

  @override
  Future<void> show(int id, String? title, String? body, {String? payload}) async {}
}
