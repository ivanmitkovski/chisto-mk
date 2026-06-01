import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:chisto_infrastructure/core/profile/profile_avatar_sync.dart';
import 'package:chisto_infrastructure/core/storage/secure_token_storage.dart';
import 'package:feature_auth/src/data/api_auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/widget_test_bootstrap.dart';

class _RecordingAvatarSync implements ProfileAvatarSync {
  String? lastRemoteUrl;
  int clearCount = 0;

  @override
  void clearAll() {
    clearCount++;
    lastRemoteUrl = null;
  }

  @override
  void setRemoteUrl(String? remoteUrl) {
    lastRemoteUrl = remoteUrl;
  }
}

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
      return const ApiResponse(
        statusCode: 200,
        json: <String, dynamic>{
          'id': 'user-1',
          'firstName': 'A',
          'lastName': 'B',
          'phoneNumber': '+38970111222',
          'organizerCertifiedAt': '2026-03-15T10:00:00.000Z',
          'avatarUrl': 'https://cdn.example/avatar.jpg',
        },
      );
    }
    return super.get(path, headers: headers);
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
          'accessToken': 'new-access',
          'refreshToken': 'new-refresh',
          'user': <String, dynamic>{
            'id': 'user-1',
            'firstName': 'A',
            'lastName': 'B',
            'phoneNumber': '+38970111222',
            'avatarUrl': 'https://cdn.example/login-avatar.jpg',
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

/// `/auth/me` and `/auth/refresh` return 401 to simulate stale Keychain tokens.
class _StaleTokenRestoreClient extends ApiClient {
  _StaleTokenRestoreClient({required super.onUnauthorized})
    : super(config: AppConfig.dev, accessToken: () => 'stale-access');

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, String>? headers,
    RequestCancellationToken? cancellation,
  }) async {
    if (path == '/auth/me') {
      throw AppError.unauthorized();
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
    if (path == '/auth/refresh') {
      throw AppError.unauthorized();
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
    AppBootstrap.instance.suppressSessionExpiredMessage = false;
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
      await storage.saveSessionData(userId: 'user-1', displayName: 'A B');
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
    },
  );

  test(
    'restoreSession overwrites stored cert when /auth/me returns uncertified',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SecureTokenStorage storage = SecureTokenStorage(
        storage: const FlutterSecureStorage(),
      );
      await storage.saveTokens(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      );
      await storage.saveSessionData(userId: 'user-1', displayName: 'A B');
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
    },
  );

  test('restoreSession syncs avatar URL from /auth/me', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SecureTokenStorage storage = SecureTokenStorage(
      storage: const FlutterSecureStorage(),
    );
    await storage.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    await storage.saveSessionData(userId: 'user-1', displayName: 'A B');

    final _RecordingAvatarSync avatarSync = _RecordingAvatarSync();
    final ApiAuthRepository repo = ApiAuthRepository(
      client: _RestoreSessionTestApiClient(),
      authState: AuthState(),
      tokenStorage: storage,
      preferences: await SharedPreferences.getInstance(),
      avatarSync: avatarSync,
    );

    await repo.restoreSession();

    expect(avatarSync.lastRemoteUrl, 'https://cdn.example/avatar.jpg');
  });

  test(
    'restoreSession rejects stale tokens without unauthorized callback',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SecureTokenStorage storage = SecureTokenStorage(
        storage: const FlutterSecureStorage(),
      );
      await storage.saveTokens(
        accessToken: 'stale-access',
        refreshToken: 'stale-refresh',
      );
      await storage.saveSessionData(userId: 'user-1', displayName: 'A B');

      final AuthState authState = AuthState();
      int unauthorizedCalls = 0;
      final _StaleTokenRestoreClient client = _StaleTokenRestoreClient(
        onUnauthorized: () => unauthorizedCalls++,
      );
      final ApiAuthRepository repo = ApiAuthRepository(
        client: client,
        authState: authState,
        tokenStorage: storage,
        preferences: await SharedPreferences.getInstance(),
      );
      client.refreshSession = () async => RefreshOutcome.serverRejected;

      await repo.restoreSession();

      expect(unauthorizedCalls, 0);
      expect(authState.isAuthenticated, isFalse);
      expect(
        AppBootstrap.instance.consumeSuppressSessionExpiredMessage(),
        isTrue,
      );
    },
  );

  test('restoreSession clears avatar when no stored access token', () async {
    final _RecordingAvatarSync avatarSync = _RecordingAvatarSync();
    final ApiAuthRepository repo = ApiAuthRepository(
      client: _RestoreSessionTestApiClient(),
      authState: AuthState(),
      tokenStorage: SecureTokenStorage(storage: const FlutterSecureStorage()),
      preferences: await SharedPreferences.getInstance(),
      avatarSync: avatarSync,
    );

    await repo.restoreSession();

    expect(avatarSync.clearCount, 1);
  });

  test('signIn syncs avatar URL from login user payload', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final _RecordingAvatarSync avatarSync = _RecordingAvatarSync();
    final ApiAuthRepository repo = ApiAuthRepository(
      client: _RestoreSessionTestApiClient(),
      authState: AuthState(),
      tokenStorage: SecureTokenStorage(storage: const FlutterSecureStorage()),
      preferences: await SharedPreferences.getInstance(),
      avatarSync: avatarSync,
    );

    await repo.signIn(phoneNumber: '+38970111222', password: 'Password1!');

    expect(avatarSync.lastRemoteUrl, 'https://cdn.example/login-avatar.jpg');
  });
}
