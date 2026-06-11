import 'dart:async';

import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:chisto_infrastructure/core/storage/secure_token_storage.dart';
import 'package:feature_auth/src/data/api_auth_repository.dart';
import 'package:feature_auth/src/domain/refresh_outcome.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/widget_test_bootstrap.dart';

/// Delays `/auth/refresh` until [releaseRefresh] so tests can interleave login.
class _DelayedRefreshApiClient extends ApiClient {
  _DelayedRefreshApiClient({
    required this.releaseRefresh,
    required super.onUnauthorized,
    required AuthState authState,
  }) : super(
         config: AppConfig.dev,
         accessToken: () => authState.accessToken,
         sessionEpoch: () => authState.sessionEpoch,
       );

  final Completer<void> releaseRefresh;

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
          'phoneNumber': '+38970111222',
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
    if (path == '/auth/refresh') {
      await releaseRefresh.future;
      throw AppError.unauthorized();
    }
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
    'refreshSession returns success when login completes during stale refresh',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SecureTokenStorage storage = SecureTokenStorage(
        storage: const FlutterSecureStorage(),
      );
      await storage.saveTokens(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
      );

      final AuthState authState = AuthState();
      final Completer<void> releaseRefresh = Completer<void>();
      final _DelayedRefreshApiClient client = _DelayedRefreshApiClient(
        releaseRefresh: releaseRefresh,
        onUnauthorized: (_) {},
        authState: authState,
      );
      final ApiAuthRepository repo = ApiAuthRepository(
        client: client,
        authState: authState,
        tokenStorage: storage,
        preferences: await SharedPreferences.getInstance(),
      );
      client.refreshSession = () => repo.refreshSession();

      final Future<RefreshOutcome> refreshFuture = repo.refreshSession();

      await repo.signIn(phoneNumber: '+38970111222', password: 'secret');

      releaseRefresh.complete();
      final RefreshOutcome outcome = await refreshFuture;

      expect(outcome, RefreshOutcome.success);
      expect(authState.isAuthenticated, isTrue);
      expect(authState.accessToken, 'new-access');
      expect(await storage.accessToken, 'new-access');
      expect(await storage.refreshToken, 'new-refresh');
    },
  );

  test('invalidateLocalSession with stale observedEpoch is a no-op', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SecureTokenStorage storage = SecureTokenStorage(
      storage: const FlutterSecureStorage(),
    );
    await storage.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );

    final AuthState authState = AuthState();
    authState.setAuthenticated(
      userId: 'user-1',
      displayName: 'A B',
      accessToken: 'access-token',
    );
    final int epochAfterLogin = authState.sessionEpoch;

    final ApiAuthRepository repo = ApiAuthRepository(
      client: ApiClient(
        config: AppConfig.dev,
        accessToken: () => authState.accessToken,
        sessionEpoch: () => authState.sessionEpoch,
        onUnauthorized: (_) {},
      ),
      authState: authState,
      tokenStorage: storage,
      preferences: await SharedPreferences.getInstance(),
    );

    await repo.invalidateLocalSession(observedEpoch: epochAfterLogin - 1);

    expect(authState.isAuthenticated, isTrue);
    expect(authState.accessToken, 'access-token');
    expect(await storage.accessToken, 'access-token');
  });
}
