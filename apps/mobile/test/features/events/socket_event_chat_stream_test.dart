import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:feature_events/src/data/chat/event_chat_connection_status.dart';
import 'package:feature_events/src/data/chat/socket_event_chat_stream.dart';
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

  test('connectionStatus getter reflects last emitted status', () {
    final AuthState auth = AuthState();
    final SocketEventChatStream stream = SocketEventChatStream(
      baseUrl: 'http://localhost:3000',
      authState: auth,
    );
    expect(stream.connectionStatus, EventChatConnectionStatus.disconnected);
    stream.dispose();
  });
}
