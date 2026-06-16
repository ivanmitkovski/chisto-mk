import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:feature_reports/src/data/reports_realtime/reports_owner_socket_stream.dart';
import 'package:feature_reports/src/data/reports_realtime/reports_realtime_connection_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('escalates to offline after sustained reconnecting', () async {
    final AuthState auth = AuthState()
      ..setAuthenticated(userId: 'u1', displayName: 'Test', accessToken: 'tok');
    final ReportsOwnerSocketStream stream = ReportsOwnerSocketStream(
      baseUrl: 'http://127.0.0.1:9',
      authState: auth,
      offlineEscalationAfter: const Duration(milliseconds: 50),
    )..connectDisabledForTest = true;
    addTearDown(stream.dispose);

    stream.hasReachedLive.value = true;
    stream.enterReconnectingForTest();

    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(
      stream.connectionState.value,
      ReportsRealtimeConnectionState.offline,
    );
  });

  test('requestReconnect leaves connecting and clears offline', () {
    final AuthState auth = AuthState()
      ..setAuthenticated(userId: 'u1', displayName: 'Test', accessToken: 'tok');
    final ReportsOwnerSocketStream stream = ReportsOwnerSocketStream(
      baseUrl: 'http://127.0.0.1:9',
      authState: auth,
    )..connectDisabledForTest = true;
    addTearDown(stream.dispose);

    stream.connectionState.value = ReportsRealtimeConnectionState.offline;
    stream.requestReconnect();

    expect(
      stream.connectionState.value,
      ReportsRealtimeConnectionState.connecting,
    );
  });
}
