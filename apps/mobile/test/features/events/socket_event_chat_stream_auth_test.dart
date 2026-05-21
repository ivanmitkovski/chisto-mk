import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/features/auth/domain/refresh_outcome.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_connection_status.dart';
import 'package:chisto_mobile/features/events/data/chat/socket_event_chat_stream.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SocketEventChatStream AUTH_FAILED handling', () {
    test('serverRejected invokes onAuthRejected once', () async {
      var refreshCalls = 0;
      var rejectedCalls = 0;
      final AuthState auth = AuthState();
      auth.setAuthenticated(
        userId: 'u1',
        displayName: 'Test',
        accessToken: 'access',
      );
      final SocketEventChatStream stream = SocketEventChatStream(
        baseUrl: 'http://localhost:3000',
        authState: auth,
        sessionRefresh: () async {
          refreshCalls += 1;
          return RefreshOutcome.serverRejected;
        },
        onAuthRejected: () => rejectedCalls += 1,
      );

      await stream.handleAuthFailedForTest('e1');

      expect(refreshCalls, 1);
      expect(rejectedCalls, 1);
      stream.dispose();
    });

    test('transient does not call onAuthRejected', () {
      var rejectedCalls = 0;
      final AuthState auth = AuthState();
      auth.setAuthenticated(
        userId: 'u1',
        displayName: 'Test',
        accessToken: 'access',
      );
      final SocketEventChatStream stream = SocketEventChatStream(
        baseUrl: 'http://localhost:3000',
        authState: auth,
        onAuthRejected: () => rejectedCalls += 1,
      );

      stream.applyAuthRefreshOutcomeForTest('e1', RefreshOutcome.transient);

      expect(rejectedCalls, 0);
      stream.dispose();
    });

    test('transient sets reconnecting not disconnected', () {
      final AuthState auth = AuthState();
      auth.setAuthenticated(
        userId: 'u1',
        displayName: 'Test',
        accessToken: 'access',
      );
      final SocketEventChatStream stream = SocketEventChatStream(
        baseUrl: 'http://localhost:3000',
        authState: auth,
      );

      stream.applyAuthRefreshOutcomeForTest('e1', RefreshOutcome.transient);

      expect(stream.connectionStatus, EventChatConnectionStatus.reconnecting);
      stream.dispose();
    });
  });
}
