import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/core/network/request_cancellation.dart';
import 'package:chisto_mobile/core/storage/secure_token_storage.dart';
import 'package:chisto_mobile/features/auth/data/api_auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RestoreSessionTestApiClient extends ApiClient {
  _RestoreSessionTestApiClient()
      : super(
          config: AppConfig.dev,
          accessToken: () => null,
          onUnauthorized: () {},
        );

  Object? getBehavior = 'ok';

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, String>? headers,
    RequestCancellationToken? cancellation,
  }) async {
    if (path == '/auth/me') {
      if (getBehavior == 'network') {
        throw AppError.network();
      }
      if (getBehavior == 'uncertified') {
        return const ApiResponse(
          statusCode: 200,
          json: <String, dynamic>{
            'id': 'user-1',
            'firstName': 'A',
            'lastName': 'B',
            'phoneNumber': '+38970111222',
            // Explicit null: server certifies "not certified" (field present).
            'organizerCertifiedAt': null,
          },
        );
      }
      return ApiResponse(
        statusCode: 200,
        json: <String, dynamic>{
          'id': 'user-1',
          'firstName': 'A',
          'lastName': 'B',
          'phoneNumber': '+38970111222',
          'organizerCertifiedAt': '2026-03-15T10:00:00.000Z',
        },
      );
    }
    return super.get(path, headers: headers);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test(
      'restoreSession hydrates organizerCertifiedAt from secure storage when /auth/me fails',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SecureTokenStorage storage = SecureTokenStorage(
      storage: const FlutterSecureStorage(),
    );
    await storage.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    await storage.saveSessionData(
      userId: 'user-1',
      displayName: 'A B',
    );
    await storage.writeOrganizerCertifiedAt(DateTime.utc(2026, 2, 1, 12));

    final AuthState authState = AuthState();
    final _RestoreSessionTestApiClient client = _RestoreSessionTestApiClient()
      ..getBehavior = 'network';

    final ApiAuthRepository repo = ApiAuthRepository(
      client: client,
      authState: authState,
      tokenStorage: storage,
      preferences: await SharedPreferences.getInstance(),
    );

    await repo.restoreSession();

    expect(authState.isAuthenticated, isTrue);
    expect(authState.isOrganizerCertified, isTrue);
    expect(authState.organizerCertifiedAt, DateTime.utc(2026, 2, 1, 12));
  });

  test('restoreSession overwrites stored cert when /auth/me returns uncertified',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SecureTokenStorage storage = SecureTokenStorage(
      storage: const FlutterSecureStorage(),
    );
    await storage.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    await storage.saveSessionData(
      userId: 'user-1',
      displayName: 'A B',
    );
    await storage.writeOrganizerCertifiedAt(DateTime.utc(2026, 2, 1, 12));

    final AuthState authState = AuthState();
    final _RestoreSessionTestApiClient client = _RestoreSessionTestApiClient()
      ..getBehavior = 'uncertified';

    final ApiAuthRepository repo = ApiAuthRepository(
      client: client,
      authState: authState,
      tokenStorage: storage,
      preferences: await SharedPreferences.getInstance(),
    );

    await repo.restoreSession();

    expect(authState.isOrganizerCertified, isFalse);
    expect(await storage.organizerCertifiedAtIso, isNull);
  });
}
