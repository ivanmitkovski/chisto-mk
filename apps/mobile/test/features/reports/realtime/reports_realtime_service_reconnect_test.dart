import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/features/reports/data/reports_realtime/reports_owner_socket_stream.dart';
import 'package:chisto_mobile/features/reports/data/reports_realtime/reports_realtime_connection_state.dart';
import 'package:chisto_mobile/features/reports/data/reports_realtime/reports_realtime_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contract: [ReportsRealtimeService] forwards streams/notifiers and delegates
/// [requestReconnect] to the underlying transport. Full transport-level reconnect
/// tests need a follow-up DI change to inject [ReportsOwnerSocketStream] in production.
class _RecordingTransport extends ReportsOwnerSocketStream {
  _RecordingTransport(AuthState auth)
    : super(
        baseUrl: 'http://127.0.0.1:9',
        authState: auth,
        sessionRefresh: null,
      );

  int reconnectCalls = 0;

  @override
  void requestReconnect() {
    reconnectCalls++;
    connectionState.value = ReportsRealtimeConnectionState.reconnecting;
    reconnectStreakSinceLive.value = reconnectStreakSinceLive.value + 1;
  }
}

void main() {
  test('delegates connectionState, events, streak; requestReconnect hits transport', () {
    final AuthState auth = AuthState()
      ..setAuthenticated(
        userId: 'u1',
        displayName: 'Test',
        accessToken: 'tok',
      );
    final _RecordingTransport transport = _RecordingTransport(auth);
    final ReportsRealtimeService svc = ReportsRealtimeService.withTransport(transport);

    expect(identical(svc.events, transport.events), isTrue);
    expect(identical(svc.connectionState, transport.connectionState), isTrue);
    expect(identical(svc.reconnectStreakSinceLive, transport.reconnectStreakSinceLive), isTrue);

    expect(transport.reconnectCalls, 0);
    svc.requestReconnect();
    expect(transport.reconnectCalls, 1);
    expect(svc.connectionState.value, ReportsRealtimeConnectionState.reconnecting);
    expect(svc.reconnectStreakSinceLive.value, 1);
  });
}
