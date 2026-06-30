import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/storage/secure_token_storage.dart';
import 'package:feature_auth/src/data/api_auth_repository.dart';
import 'package:feature_auth/src/domain/refresh_outcome.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'refreshSession returns serverRejected on 401 refresh response',
    () async {
      final http.Client mock = MockClient((http.Request request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          return http.Response(
            '{"code":"UNAUTHORIZED","message":"invalid"}',
            401,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      });
      final ApiClient client = ApiClient(
        config: AppConfig.local,
        accessToken: () => 'access',
        onUnauthorized: (_) {},
        httpClient: mock,
      );
      final SecureTokenStorage tokens = SecureTokenStorage(
        storage: const FlutterSecureStorage(),
      );
      await tokens.saveTokens(accessToken: 'access', refreshToken: 'refresh');
      final ApiAuthRepository repo = ApiAuthRepository(
        client: client,
        authState: AuthState(),
        tokenStorage: tokens,
        preferences: await SharedPreferences.getInstance(),
      );

      expect(await repo.refreshSession(), RefreshOutcome.serverRejected);
    },
  );

  test('refreshSession returns transient on network failure', () async {
    final ApiClient client = ApiClient(
      config: AppConfig.local,
      accessToken: () => 'access',
      onUnauthorized: (_) {},
      httpClient: MockClient((http.Request request) async {
        throw http.ClientException('connection refused');
      }),
    );
    final SecureTokenStorage tokens = SecureTokenStorage(
      storage: const FlutterSecureStorage(),
    );
    await tokens.saveTokens(accessToken: 'access', refreshToken: 'refresh');
    final ApiAuthRepository repo = ApiAuthRepository(
      client: client,
      authState: AuthState(),
      tokenStorage: tokens,
      preferences: await SharedPreferences.getInstance(),
    );

    expect(await repo.refreshSession(), RefreshOutcome.transient);
  });

  test(
    'refreshSession returns serverRejected when refresh token missing',
    () async {
      final ApiAuthRepository repo = ApiAuthRepository(
        client: ApiClient(
          config: AppConfig.local,
          accessToken: () => null,
          onUnauthorized: (_) {},
        ),
        authState: AuthState(),
        tokenStorage: SecureTokenStorage(storage: const FlutterSecureStorage()),
        preferences: await SharedPreferences.getInstance(),
      );

      expect(await repo.refreshSession(), RefreshOutcome.serverRejected);
    },
  );
}
