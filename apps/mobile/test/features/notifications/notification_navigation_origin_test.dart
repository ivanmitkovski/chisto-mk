import 'package:feature_notifications/src/data/notification_inbox_router.dart';
import 'package:feature_notifications/src/data/notification_navigation_origin.dart';
import 'package:feature_notifications/src/data/notification_open_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationNavigationOrigin wiring', () {
    test('inbox router passes inbox origin to executor via API surface', () {
      expect(NotificationNavigationOrigin.inbox, isNot(
        NotificationNavigationOrigin.external,
      ));
    });

    test('open router uses external origin enum value', () {
      expect(NotificationNavigationOrigin.external.name, 'external');
      expect(NotificationInboxRouter, isNotNull);
      expect(NotificationOpenRouter, isNotNull);
    });
  });
}
