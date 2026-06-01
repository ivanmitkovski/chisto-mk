import 'package:chisto_infrastructure/core/config/app_config.dart';
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
      onUnauthorized: () => calls += 1,
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
      onUnauthorized: () => calls += 1,
      httpClient: MockClient((_) async => http.Response('{}', 200)),
    );

    client.notifySessionAuthRejected();
    client.resetSessionAuthFailureGuard();
    client.notifySessionAuthRejected();

    expect(calls, 2);
  });
}
