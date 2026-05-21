import 'package:chisto_mobile/features/notifications/data/push_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encode and decode round-trip FCM data payload', () {
    final Map<String, dynamic> data = <String, dynamic>{
      'notificationId': 'n-1',
      'type': 'COMMENT',
      'siteId': 'site-1',
    };
    final String? encoded =
        PushNotificationService.encodeNotificationPayloadForTest(data);
    expect(encoded, isNotNull);
    final Map<String, dynamic>? decoded =
        PushNotificationService.decodeNotificationPayloadForTest(encoded);
    expect(decoded, data);
  });
}
