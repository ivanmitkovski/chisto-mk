import 'package:chisto_mobile/features/notifications/data/push_notification_service.dart';
import 'package:chisto_mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNotificationsRepository implements NotificationsRepository {
  int registerCalls = 0;
  String? lastToken;

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? appVersion,
    String? locale,
  }) async {
    registerCalls++;
    lastToken = token;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('syncDeviceTokenWithBackend skips when not authenticated', () async {
    final _FakeNotificationsRepository repo = _FakeNotificationsRepository();
    final PushNotificationService push = PushNotificationService(
      repository: repo,
      isAuthenticated: () => false,
    );

    await push.syncDeviceTokenWithBackend();

    expect(repo.registerCalls, 0);
  });

  test('registerTokenForTest skips duplicate token API calls', () async {
    final _FakeNotificationsRepository repo = _FakeNotificationsRepository();
    final PushNotificationService push = PushNotificationService(
      repository: repo,
      isAuthenticated: () => true,
    );

    await push.registerTokenForTest('same-fcm-token');
    await push.registerTokenForTest('same-fcm-token');
    await push.registerTokenForTest('new-fcm-token');

    expect(repo.registerCalls, 2);
    expect(push.lastRegisteredTokenForTest, 'new-fcm-token');
  });
}
