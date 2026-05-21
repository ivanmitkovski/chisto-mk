import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/auth/domain/refresh_outcome.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('retry 401 after successful refresh does not invoke onUnauthorized', () async {
    var unauthorizedCalls = 0;
    var protectedHits = 0;

    final mock = MockClient((http.Request request) async {
      if (request.url.path.endsWith('/protected')) {
        protectedHits += 1;
        return http.Response(
          '{"code":"SESSION_REVOKED","message":"revoked"}',
          401,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });

    final client = ApiClient(
      config: AppConfig.local,
      accessToken: () => 'token',
      onUnauthorized: () => unauthorizedCalls += 1,
      httpClient: mock,
    );
    client.refreshSession = () async => RefreshOutcome.success;

    await expectLater(
      client.get('/protected'),
      throwsA(
        isA<AppError>().having((AppError e) => e.code, 'code', 'SESSION_REVOKED'),
      ),
    );

    expect(protectedHits, 2);
    expect(unauthorizedCalls, 0);
  });

  test('refresh serverRejected invokes onUnauthorized once', () async {
    var unauthorizedCalls = 0;

    final mock = MockClient((http.Request request) async {
      if (request.url.path.endsWith('/protected')) {
        return http.Response(
          '{"code":"UNAUTHORIZED","message":"expired"}',
          401,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });

    final client = ApiClient(
      config: AppConfig.local,
      accessToken: () => 'token',
      onUnauthorized: () => unauthorizedCalls += 1,
      httpClient: mock,
    );
    client.refreshSession = () async => RefreshOutcome.serverRejected;

    await expectLater(
      client.get('/protected'),
      throwsA(isA<AppError>().having((AppError e) => e.code, 'code', 'UNAUTHORIZED')),
    );

    expect(unauthorizedCalls, 1);
  });
}
