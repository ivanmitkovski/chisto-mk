import 'package:chisto_infrastructure/core/network/realtime_socket_transport_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RealtimeSocketTransportPolicy', () {
    test('prefers websocket-only by default', () {
      final RealtimeSocketTransportPolicy policy =
          RealtimeSocketTransportPolicy(preferWebSocket: true, wsOnly: false);

      expect(policy.currentTransports(), <String>['websocket']);
      expect(policy.describeTransports(), 'websocket');
    });

    test('falls back to polling+websocket after repeated failures', () {
      final RealtimeSocketTransportPolicy policy =
          RealtimeSocketTransportPolicy(
            preferWebSocket: true,
            wsOnly: false,
            fallbackAfterFailedAttempts: 2,
          );

      expect(policy.recordConnectFailure(), isFalse);
      expect(policy.currentTransports(), <String>['websocket']);

      expect(policy.recordConnectFailure(), isTrue);
      expect(policy.currentTransports(), <String>['polling', 'websocket']);
      expect(policy.usingPollingFallback, isTrue);
    });

    test('resets to websocket-first after successful connect', () {
      final RealtimeSocketTransportPolicy policy =
          RealtimeSocketTransportPolicy(
            preferWebSocket: true,
            fallbackAfterFailedAttempts: 1,
          );

      expect(policy.recordConnectFailure(), isTrue);
      expect(policy.currentTransports(), <String>['polling', 'websocket']);

      policy.recordConnectSuccess();
      expect(policy.currentTransports(), <String>['websocket']);
      expect(policy.usingPollingFallback, isFalse);
    });

    test('wsOnly never falls back', () {
      final RealtimeSocketTransportPolicy policy =
          RealtimeSocketTransportPolicy(wsOnly: true);

      expect(policy.recordConnectFailure(), isFalse);
      expect(policy.recordConnectFailure(), isFalse);
      expect(policy.currentTransports(), <String>['websocket']);
    });
  });
}
