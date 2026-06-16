import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:feature_reports/src/data/reports_realtime/reports_owner_socket_stream.dart';
import 'package:feature_reports/src/data/reports_realtime/reports_realtime_connection_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('markLiveForTest sets live; connecting alone does not', () {
    final AuthState auth = AuthState()
      ..setAuthenticated(userId: 'u1', displayName: 'Test', accessToken: 'tok');
    final ReportsOwnerSocketStream stream = ReportsOwnerSocketStream(
      baseUrl: 'http://127.0.0.1:9',
      authState: auth,
    )..connectDisabledForTest = true;
    addTearDown(stream.dispose);

    stream.connectionState.value = ReportsRealtimeConnectionState.connecting;
    expect(stream.hasReachedLive.value, isFalse);

    stream.markLiveForTest();
    expect(stream.hasReachedLive.value, isTrue);
    expect(stream.connectionState.value, ReportsRealtimeConnectionState.live);
  });

  test(
    'duplicate setAuthenticated with same token does not reconnect while disconnected',
    () {
      final AuthState auth = AuthState()
        ..setAuthenticated(
          userId: 'u1',
          displayName: 'Test',
          accessToken: 'tok',
        );
      final ReportsOwnerSocketStream stream = ReportsOwnerSocketStream(
        baseUrl: 'http://127.0.0.1:9',
        authState: auth,
      )..connectDisabledForTest = true;
      addTearDown(stream.dispose);

      stream.start();
      expect(stream.connectionState.value, isNull);

      auth.setAuthenticated(
        userId: 'u1',
        displayName: 'Test User',
        accessToken: 'tok',
      );
      expect(stream.connectionState.value, isNull);
    },
  );
}
