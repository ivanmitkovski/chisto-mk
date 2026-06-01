import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'retry 401 after successful refresh does not invoke onUnauthorized',
    () async {
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
          isA<AppError>().having(
            (AppError e) => e.code,
            'code',
            'SESSION_REVOKED',
          ),
        ),
      );

      expect(protectedHits, 2);
      expect(unauthorizedCalls, 0);
    },
  );

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
      throwsA(
        isA<AppError>().having((AppError e) => e.code, 'code', 'UNAUTHORIZED'),
      ),
    );

    expect(unauthorizedCalls, 1);
  });

  test('INVALID_TOKEN on optional-auth route retries after refresh', () async {
    var unauthorizedCalls = 0;
    var feedHits = 0;

    final mock = MockClient((http.Request request) async {
      if (request.url.path.endsWith('/sites/feed')) {
        feedHits += 1;
        if (feedHits == 1) {
          return http.Response(
            '{"code":"INVALID_TOKEN","message":"Invalid or expired authentication token"}',
            401,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }
        return http.Response(
          '{"data":[]}',
          200,
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

    final response = await client.get('/sites/feed');

    expect(response.statusCode, 200);
    expect(feedHits, 2);
    expect(unauthorizedCalls, 0);
  });

  test(
    'INVALID_TOKEN refresh serverRejected invokes onUnauthorized once',
    () async {
      var unauthorizedCalls = 0;

      final mock = MockClient((http.Request request) async {
        if (request.url.path.endsWith('/sites/feed')) {
          return http.Response(
            '{"code":"INVALID_TOKEN","message":"Invalid or expired authentication token"}',
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
        client.get('/sites/feed'),
        throwsA(
          isA<AppError>().having(
            (AppError e) => e.code,
            'code',
            'INVALID_TOKEN',
          ),
        ),
      );

      expect(unauthorizedCalls, 1);
    },
  );

  test(
    'multipart refresh serverRejected invokes onUnauthorized once',
    () async {
      var unauthorizedCalls = 0;
      var uploadHits = 0;

      final mock = MockClient((http.Request request) async {
        if (request.url.path.contains('/auth/me/avatar')) {
          uploadHits += 1;
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
        client.multipartPostWithRetry(
          '/auth/me/avatar',
          files: <MultipartFileData>[
            const MultipartFileData(
              field: 'avatar',
              bytes: <int>[1, 2, 3],
              fileName: 'a.jpg',
              mimeType: 'image/jpeg',
            ),
          ],
        ),
        throwsA(
          isA<AppError>().having(
            (AppError e) => e.code,
            'code',
            'UNAUTHORIZED',
          ),
        ),
      );

      expect(uploadHits, 1);
      expect(unauthorizedCalls, 1);
    },
  );

  test('GET retries transient 5xx errors with bounded backoff', () async {
    var feedHits = 0;

    final mock = MockClient((http.Request request) async {
      if (request.url.path.endsWith('/sites/feed')) {
        feedHits += 1;
        if (feedHits <= 2) {
          return http.Response('server error', 503);
        }
        return http.Response(
          '{"data":[]}',
          200,
          headers: <String, String>{'content-type': 'application/json'},
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

    final DateTime start = DateTime.now();
    final response = await client.get('/sites/feed');
    final Duration elapsed = DateTime.now().difference(start);

    expect(response.statusCode, 200);
    expect(feedHits, 3);
    expect(elapsed.inMilliseconds, greaterThanOrEqualTo(300));
  });

  test('GET does not retry after max transient attempts', () async {
    var feedHits = 0;

    final mock = MockClient((http.Request request) async {
      if (request.url.path.endsWith('/sites/feed')) {
        feedHits += 1;
        return http.Response('server error', 503);
      }
      return http.Response('not found', 404);
    });

    final client = ApiClient(
      config: AppConfig.local,
      accessToken: () => 'token',
      onUnauthorized: () {},
      httpClient: mock,
    );

    await expectLater(
      client.get('/sites/feed'),
      throwsA(
        isA<AppError>().having((AppError e) => e.code, 'code', 'SERVER_ERROR'),
      ),
    );

    expect(feedHits, 3);
  });

  test('POST does not retry transient 5xx errors', () async {
    var submitHits = 0;

    final mock = MockClient((http.Request request) async {
      if (request.url.path.endsWith('/reports') && request.method == 'POST') {
        submitHits += 1;
        return http.Response('server error', 503);
      }
      return http.Response('not found', 404);
    });

    final client = ApiClient(
      config: AppConfig.local,
      accessToken: () => 'token',
      onUnauthorized: () {},
      httpClient: mock,
    );

    await expectLater(
      client.post('/reports', body: <String, dynamic>{}),
      throwsA(
        isA<AppError>().having((AppError e) => e.code, 'code', 'SERVER_ERROR'),
      ),
    );

    expect(submitHits, 1);
  });
}
