import 'package:chisto_mobile/features/events/data/chat/socket_event_chat_stream.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chatSocketNeedsReconnectForNewToken', () {
    test('false when socket not connected', () {
      expect(
        chatSocketNeedsReconnectForNewToken(
          socketConnected: false,
          newAccessToken: 'b',
          tokenAtHandshake: 'a',
        ),
        false,
      );
    });

    test('false when token unchanged', () {
      expect(
        chatSocketNeedsReconnectForNewToken(
          socketConnected: true,
          newAccessToken: 'same',
          tokenAtHandshake: 'same',
        ),
        false,
      );
    });

    test('false when new token empty', () {
      expect(
        chatSocketNeedsReconnectForNewToken(
          socketConnected: true,
          newAccessToken: '',
          tokenAtHandshake: 'a',
        ),
        false,
      );
    });

    test('true when connected and access token rotated', () {
      expect(
        chatSocketNeedsReconnectForNewToken(
          socketConnected: true,
          newAccessToken: 'fresh',
          tokenAtHandshake: 'stale',
        ),
        true,
      );
    });
  });
}
