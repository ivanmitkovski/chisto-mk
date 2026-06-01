import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:feature_auth/src/domain/refresh_outcome.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('parallel 401s share one refresh and all retry', () async {
    var refreshCalls = 0;
    var protectedHits = 0;

    final mock = MockClient((http.Request request) async {
      if (request.url.path.endsWith('/protected')) {
        protectedHits += 1;
        if (protectedHits <= 5) {
          return http.Response(
            '{"code":"UNAUTHORIZED","message":"expired"}',
            401,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          '{"ok":true}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });

    final client = ApiClient(
      config: AppConfig.local,
      accessToken: () => 'token',
      onUnauthorized: () {},
      httpClient: mock,
    );
    client.refreshSession = () async {
      refreshCalls += 1;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      return RefreshOutcome.success;
    };

    final results = await Future.wait(
      List.generate(5, (_) => client.get('/protected')),
    );

    expect(refreshCalls, 1);
    expect(results.every((r) => r.statusCode == 200), isTrue);
  });

  test('adds stable device id header to API requests', () async {
    late http.Request captured;
    final mock = MockClient((http.Request request) async {
      captured = request;
      return http.Response(
        '{"ok":true}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final client = ApiClient(
      config: AppConfig.local,
      accessToken: () => 'token',
      onUnauthorized: () {},
      deviceIdHeader: () async => 'device-123',
      httpClient: mock,
    );

    await client.get('/protected');

    expect(captured.headers['X-Device-Id'], 'device-123');
  });
}
