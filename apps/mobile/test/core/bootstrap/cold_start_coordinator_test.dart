import 'package:chisto_infrastructure/core/bootstrap/cold_start_coordinator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(ColdStartCoordinator.instance.resetSession);

  test('peekPendingIntent returns push before deep link', () {
    final ColdStartCoordinator c = ColdStartCoordinator.instance;
    c.markBootstrapReady();
    c.markSessionReady();
    c.queueDeepLink(Uri.parse('https://chisto.mk/events/evt-1'));
    c.queueColdStartPush(
      const RemoteMessage(
        data: <String, String>{'type': 'EVENT_CHAT', 'eventId': 'evt-1'},
      ),
    );
    final LaunchIntent? intent = c.peekPendingIntent();
    expect(intent, isNotNull);
    expect(intent!.kind, LaunchIntentKind.pushTap);
  });

  test('peekPendingIntent is null until bootstrap and session ready', () {
    final ColdStartCoordinator c = ColdStartCoordinator.instance;
    c.queueColdStartPush(
      const RemoteMessage(data: <String, String>{'type': 'SYSTEM'}),
    );
    expect(c.peekPendingIntent(), isNull);
    c.markBootstrapReady();
    expect(c.peekPendingIntent(), isNull);
    c.markSessionReady();
    expect(c.peekPendingIntent(), isNotNull);
  });
}
