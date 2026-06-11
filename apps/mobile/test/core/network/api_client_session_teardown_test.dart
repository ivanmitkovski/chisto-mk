import 'package:chisto_core/chisto_core.dart';
import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('notifySessionAuthRejected invokes onUnauthorized only once', () {
    var calls = 0;
    final client = ApiClient(
      config: AppConfig.local,
      accessToken: () => 'token',
      onUnauthorized: (_) => calls += 1,
      httpClient: MockClient((_) async => http.Response('{}', 200)),
    );

    client.notifySessionAuthRejected();
    client.notifySessionAuthRejected();
    client.notifySessionAuthRejected();

    expect(calls, 1);
  });

  test('resetSessionAuthFailureGuard allows a second teardown after login', () {
    var calls = 0;
    final client = ApiClient(
      config: AppConfig.local,
      accessToken: () => 'token',
      onUnauthorized: (_) => calls += 1,
      httpClient: MockClient((_) async => http.Response('{}', 200)),
    );

    client.notifySessionAuthRejected();
    client.resetSessionAuthFailureGuard();
    client.notifySessionAuthRejected();

    expect(calls, 2);
  });

  test(
    '401 teardown passes the session epoch observed at request send',
    () async {
      var epoch = 3;
      int? observedEpoch;
      final client = ApiClient(
        config: AppConfig.local,
        accessToken: () => 'stale-token',
        sessionEpoch: () => epoch,
        onUnauthorized: (int e) => observedEpoch = e,
        httpClient: MockClient((_) async {
          return http.Response(
            '{"code":"UNAUTHORIZED","message":"expired"}',
            401,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }),
      );
      client.refreshSession = () async => RefreshOutcome.serverRejected;

      await expectLater(
        client.get('/notifications/unread-count'),
        throwsA(isA<AppError>()),
      );

      expect(observedEpoch, 3);
    },
  );
}
