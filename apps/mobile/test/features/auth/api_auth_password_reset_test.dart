import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/core/storage/secure_token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chisto_mobile/features/auth/data/api_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _PathCapturingApiClient extends ApiClient {
  _PathCapturingApiClient()
      : super(
          config: AppConfig.dev,
          accessToken: () => null,
          onUnauthorized: () {},
        );

  String? lastPostPath;
  Object? lastPostBody;

  @override
  Future<ApiResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    lastPostPath = path;
    lastPostBody = body;
    return const ApiResponse(
      statusCode: 200,
      json: <String, dynamic>{'expiresIn': 599},
    );
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
}
