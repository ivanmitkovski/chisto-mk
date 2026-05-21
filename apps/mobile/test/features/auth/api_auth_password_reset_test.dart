import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/core/storage/secure_token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chisto_mobile/features/auth/data/api_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/widget_test_bootstrap.dart';

class _PathCapturingApiClient extends ApiClient {
  _PathCapturingApiClient()
      : super(
          config: AppConfig.dev,
          accessToken: () => null,
          onUnauthorized: () {},
        );

  String? lastPostPath;
  Object? lastPostBody;
  Map<String, dynamic>? jsonOverride;

  @override
  Future<ApiResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    lastPostPath = path;
    lastPostBody = body;
    return ApiResponse(
      statusCode: 200,
      json: jsonOverride ?? <String, dynamic>{'expiresIn': 599},
    );
  }

  @override
  Future<ApiResponse> patch(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    lastPostPath = path;
    lastPostBody = body;
    return const ApiResponse(statusCode: 200, json: <String, dynamic>{});
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('requestPasswordReset posts to /auth/password-reset/request', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final _PathCapturingApiClient client = _PathCapturingApiClient();
    final ApiAuthRepository repo = ApiAuthRepository(
      client: client,
      authState: AuthState(),
      tokenStorage: SecureTokenStorage(
        storage: const FlutterSecureStorage(),
      ),
      preferences: await SharedPreferences.getInstance(),
    );

    final result = await repo.requestPasswordReset('+38970123456');

    expect(client.lastPostPath, '/auth/password-reset/request');
    expect(client.lastPostBody, <String, dynamic>{'phoneNumber': '+38970123456'});
    expect(result.expiresInSeconds, 599);
  });

  test('verifyPasswordResetCode posts to /auth/password-reset/verify-code', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final _PathCapturingApiClient client = _PathCapturingApiClient();
    final ApiAuthRepository repo = ApiAuthRepository(
      client: client,
      authState: AuthState(),
      tokenStorage: SecureTokenStorage(
        storage: const FlutterSecureStorage(),
      ),
      preferences: await SharedPreferences.getInstance(),
    );

    await repo.verifyPasswordResetCode('+38970123456', '4829');

    expect(client.lastPostPath, '/auth/password-reset/verify-code');
    expect(client.lastPostBody, <String, dynamic>{
      'phoneNumber': '+38970123456',
      'code': '4829',
    });
  });

  test('requestPasswordResetByEmail posts email body', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final _PathCapturingApiClient client = _PathCapturingApiClient();
    final ApiAuthRepository repo = ApiAuthRepository(
      client: client,
      authState: AuthState(),
      tokenStorage: SecureTokenStorage(
        storage: const FlutterSecureStorage(),
      ),
      preferences: await SharedPreferences.getInstance(),
    );

    await repo.requestPasswordResetByEmail('user@example.com');

    expect(client.lastPostPath, '/auth/password-reset/request');
    expect(client.lastPostBody, <String, dynamic>{'email': 'user@example.com'});
  });

  test('confirmPasswordResetByEmail posts to email confirm', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final _PathCapturingApiClient client = _PathCapturingApiClient();
    final ApiAuthRepository repo = ApiAuthRepository(
      client: client,
      authState: AuthState(),
      tokenStorage: SecureTokenStorage(
        storage: const FlutterSecureStorage(),
      ),
      preferences: await SharedPreferences.getInstance(),
    );

    await repo.confirmPasswordResetByEmail(
      token: 'opaque-token',
      newPassword: 'NewPass123!',
    );

    expect(client.lastPostPath, '/auth/password-reset/email/confirm');
    expect(client.lastPostBody, <String, dynamic>{
      'token': 'opaque-token',
      'newPassword': 'NewPass123!',
    });
  });

  test('signIn sends rememberMe flag', () async {
    await bootstrapWidgetTests();
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    final _PathCapturingApiClient client = _PathCapturingApiClient();
    final ApiAuthRepository repo = ApiAuthRepository(
      client: client,
      authState: AuthState(),
      tokenStorage: SecureTokenStorage(
        storage: const FlutterSecureStorage(),
      ),
      preferences: await SharedPreferences.getInstance(),
    );

    client.jsonOverride = <String, dynamic>{
      'accessToken': 'a',
      'refreshToken': 'r',
      'user': <String, dynamic>{
        'id': 'u1',
        'firstName': 'A',
        'lastName': 'B',
        'phoneNumber': '+38970123456',
      },
    };

    await repo.signIn(
      phoneNumber: '+38970123456',
      password: 'secret123',
      rememberMe: false,
    );

    expect(client.lastPostBody, <String, dynamic>{
      'phoneNumber': '+38970123456',
      'password': 'secret123',
      'rememberMe': false,
    });
  });
}
