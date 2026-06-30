import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:chisto_infrastructure/core/storage/secure_token_storage.dart';
import 'package:feature_auth/src/data/api_auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/widget_test_bootstrap.dart';

class _LoginApiClient extends ApiClient {
  _LoginApiClient()
    : super(
        config: AppConfig.dev,
        accessToken: () => null,
        onUnauthorized: (_) {},
      );

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, String>? headers,
    RequestCancellationToken? cancellation,
  }) async {
    if (path == '/auth/me') {
      return const ApiResponse(
        statusCode: 200,
        json: <String, dynamic>{
          'id': 'user-1',
          'firstName': 'A',
          'lastName': 'B',
          'phoneNumber': '+38970123456',
          'homeLatitude': null,
          'homeLongitude': null,
          'homeLocationSetAt': null,
        },
      );
    }
    return super.get(path, headers: headers, cancellation: cancellation);
  }

  @override
  Future<ApiResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
    RequestCancellationToken? cancellation,
  }) async {
    if (path == '/auth/login') {
      return const ApiResponse(
        statusCode: 200,
        json: <String, dynamic>{
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
          'user': <String, dynamic>{
            'id': 'user-1',
            'firstName': 'A',
            'lastName': 'B',
            'phoneNumber': '+38970123456',
          },
        },
      );
    }
    return super.post(
      path,
      headers: headers,
      body: body,
      cancellation: cancellation,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test(
    'rememberMe true persists tokens across storage instance restart',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SecureTokenStorage storage = SecureTokenStorage(
        storage: const FlutterSecureStorage(),
      );
      final ApiAuthRepository repo = ApiAuthRepository(
        client: _LoginApiClient(),
        authState: AuthState(),
        tokenStorage: storage,
        preferences: await SharedPreferences.getInstance(),
      );

      await repo.signIn(
        phoneNumber: '+38970123456',
        password: 'secret',
        rememberMe: true,
      );

      final SecureTokenStorage restarted = SecureTokenStorage(
        storage: const FlutterSecureStorage(),
      );
      expect(await restarted.accessToken, 'access-token');
      expect(await restarted.refreshToken, 'refresh-token');
    },
  );

  test('rememberMe false keeps tokens out of secure storage', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SecureTokenStorage storage = SecureTokenStorage(
      storage: const FlutterSecureStorage(),
    );
    final ApiAuthRepository repo = ApiAuthRepository(
      client: _LoginApiClient(),
      authState: AuthState(),
      tokenStorage: storage,
      preferences: await SharedPreferences.getInstance(),
    );

    await repo.signIn(
      phoneNumber: '+38970123456',
      password: 'secret',
      rememberMe: false,
    );

    expect(storage.isPersistent, isFalse);
    expect(await storage.accessToken, 'access-token');

    final SecureTokenStorage coldStart = SecureTokenStorage(
      storage: const FlutterSecureStorage(),
    );
    expect(await coldStart.accessToken, isNull);
    expect(await coldStart.refreshToken, isNull);
  });
}
