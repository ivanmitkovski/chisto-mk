import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/network/connectivity_gate.dart';
import 'package:chisto_mobile/features/auth/domain/refresh_outcome.dart';
import 'package:chisto_mobile/features/home/data/map_realtime/map_realtime_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late Future<List<ConnectivityResult>> Function() _origCheck;

  setUp(() {
    _origCheck = ConnectivityGate.check;
    ConnectivityGate.check =
        () async => <ConnectivityResult>[ConnectivityResult.wifi];
  });

  tearDown(() {
    ConnectivityGate.check = _origCheck;
  });

  test('SSE 401 with transient refresh keeps session and skips onAuthRejected',
      () async {
    var refreshCalls = 0;
    var authRejectedCalls = 0;
    final http.Client client = MockClient((http.Request request) async {
      return http.Response('', 401);
    });
    final AuthState auth = AuthState()
      ..setAuthenticated(
        userId: 'u1',
        displayName: 'Tester',
        accessToken: 't1',
      );
    final MapRealtimeService svc = MapRealtimeService(
      config: AppConfig.local,
      authState: auth,
      sessionRefresh: () async {
        refreshCalls += 1;
        return RefreshOutcome.transient;
      },
      onAuthRejected: () => authRejectedCalls += 1,
      httpClient: client,
    );

    svc.setActive(true);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(refreshCalls, greaterThanOrEqualTo(1));
    expect(authRejectedCalls, 0);
    expect(auth.isAuthenticated, isTrue);
    svc.dispose();
  });

  test('SSE 401 with serverRejected refresh invokes onAuthRejected', () async {
    var authRejectedCalls = 0;
    final http.Client client = MockClient((http.Request request) async {
      return http.Response('', 401);
    });
    final AuthState auth = AuthState()
      ..setAuthenticated(
        userId: 'u1',
        displayName: 'Tester',
        accessToken: 't1',
      );
    final MapRealtimeService svc = MapRealtimeService(
      config: AppConfig.local,
      authState: auth,
      sessionRefresh: () async => RefreshOutcome.serverRejected,
      onAuthRejected: () => authRejectedCalls += 1,
      httpClient: client,
    );

    svc.setActive(true);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(authRejectedCalls, greaterThanOrEqualTo(1));
    svc.dispose();
  });
}
