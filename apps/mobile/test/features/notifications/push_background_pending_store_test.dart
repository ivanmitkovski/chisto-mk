import 'package:chisto_mobile/features/notifications/data/push_background_pending_store.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PushBackgroundPendingStore.clearForTest();
  });

  test('recordBackgroundMessage sets inbox bump and unread count', () async {
    await PushBackgroundPendingStore.recordBackgroundMessage(
      RemoteMessage(
        data: <String, String>{
          'notificationId': 'n-1',
          'type': 'COMMENT',
          'unreadCount': '3',
        },
      ),
    );

    final PendingPushDrainResult pending =
        await PushBackgroundPendingStore.drainPending();
    expect(pending.inboxBump, isTrue);
    expect(pending.unreadCount, 3);
    expect(pending.tapPayload?['notificationId'], 'n-1');
  });

  test('drainPending clears stored keys', () async {
    await PushBackgroundPendingStore.recordBackgroundMessage(
      RemoteMessage(data: <String, String>{'unreadCount': '1'}),
    );
    await PushBackgroundPendingStore.drainPending();

    final PendingPushDrainResult again =
        await PushBackgroundPendingStore.drainPending();
    expect(again.hasWork, isFalse);
  });
}
