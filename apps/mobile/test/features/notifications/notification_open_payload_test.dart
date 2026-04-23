import 'package:chisto_mobile/features/notifications/data/notification_open_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('notificationOpenPayloadLooksLikeUuid', () {
    test('accepts lowercase UUID v4', () {
      expect(
        notificationOpenPayloadLooksLikeUuid('550e8400-e29b-41d4-a716-446655440000'),
        isTrue,
      );
    });

    test('rejects non-uuid strings', () {
      expect(notificationOpenPayloadLooksLikeUuid('not-a-uuid'), isFalse);
      expect(notificationOpenPayloadLooksLikeUuid(''), isFalse);
    });
  });

  group('notificationOpenResolveChatBarTitle', () {
    test('prefers threadTitle from data', () {
      expect(
        notificationOpenResolveChatBarTitle(
          data: <String, dynamic>{'threadTitle': ' From push '},
          notificationTitle: 'Notification title',
          cachedEventTitle: 'Cached',
        ),
        'From push',
      );
    });

    test('falls back to notification title then cache', () {
      expect(
        notificationOpenResolveChatBarTitle(
          data: <String, dynamic>{},
          notificationTitle: 'Notif',
          cachedEventTitle: null,
        ),
        'Notif',
      );
      expect(
        notificationOpenResolveChatBarTitle(
          data: <String, dynamic>{},
          notificationTitle: null,
          cachedEventTitle: 'Cached title',
        ),
        'Cached title',
      );
    });
  });
}
