import 'dart:ui' show Locale;

import 'package:feature_notifications/src/data/push_notification_service.dart';
import 'package:feature_notifications/src/domain/repositories/notifications_repository.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/fake_flutter_local_notifications_platform.dart';

class _FakeNotificationsRepository implements NotificationsRepository {
  int registerCalls = 0;
  String? lastToken;
  String? lastLocale;

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? appVersion,
    String? locale,
  }) async {
    registerCalls++;
    lastToken = token;
    lastLocale = locale;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterLocalNotificationsPlatform.instance =
        FakeFlutterLocalNotificationsPlatform();
  });

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
      resolveEffectiveLocale: () => const Locale('en'),
    );

    await push.registerTokenForTest('same-fcm-token');
    await push.registerTokenForTest('same-fcm-token');
    await push.registerTokenForTest('new-fcm-token');

    expect(repo.registerCalls, 2);
    expect(push.lastRegisteredTokenForTest, 'new-fcm-token');
  });

  test('forceLocaleRefresh re-registers when token unchanged but locale changed', () async {
    final _FakeNotificationsRepository repo = _FakeNotificationsRepository();
    Locale effective = const Locale('en');
    final PushNotificationService push = PushNotificationService(
      repository: repo,
      isAuthenticated: () => true,
      resolveEffectiveLocale: () => effective,
    );

    await push.registerTokenForTest('same-fcm-token');
    expect(repo.registerCalls, 1);
    expect(repo.lastLocale, 'en');

    effective = const Locale('sq');
    await push.registerTokenForTest('same-fcm-token', force: true);

    expect(repo.registerCalls, 2);
    expect(repo.lastLocale, 'sq');
  });

  test('initialize is idempotent when Firebase is not ready', () async {
    final _FakeNotificationsRepository repo = _FakeNotificationsRepository();
    final PushNotificationService push = PushNotificationService(
      repository: repo,
      isAuthenticated: () => true,
    );

    await push.initialize();
    expect(push.isInitialized, isTrue);
    expect(push.isFirebaseReady, isFalse);

    await push.teardownFirebaseListeners();
    await push.initialize();
    expect(push.isInitialized, isTrue);
  });

  test('organizer end-soon payload encodes as JSON for local tap decode', () {
    final String? encoded =
        PushNotificationService.encodeNotificationPayloadForTest(
          <String, dynamic>{
            'type': 'CLEANUP_EVENT',
            'eventId': '550e8400-e29b-41d4-a716-446655440000',
          },
        );
    expect(encoded, isNotNull);
    final Map<String, dynamic>? decoded =
        PushNotificationService.decodeNotificationPayloadForTest(encoded);
    expect(decoded?['type'], 'CLEANUP_EVENT');
    expect(decoded?['eventId'], '550e8400-e29b-41d4-a716-446655440000');
  });
}
