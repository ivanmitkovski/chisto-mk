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

class _RefreshRetryApiClient extends ApiClient {
  _RefreshRetryApiClient({required this.onRefresh})
    : super(
        config: AppConfig.dev,
        accessToken: () => null,
        onUnauthorized: (_) {},
      );

  final AppError? Function(int attempt) onRefresh;
  int refreshAttempts = 0;

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
    if (path == '/auth/refresh') {
      final AppError? error = onRefresh(refreshAttempts++);
      if (error != null) throw error;
      return const ApiResponse(
        statusCode: 200,
        json: <String, dynamic>{
          'accessToken': 'new-access',
          'refreshToken': 'new-refresh',
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
    'refreshSession retries INVALID_REFRESH_TOKEN then succeeds within grace',
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
      final _RefreshRetryApiClient client = _RefreshRetryApiClient(
        onRefresh: (int attempt) {
          if (attempt == 0) {
            return const AppError(
              code: 'INVALID_REFRESH_TOKEN',
              message: 'stale during rotation race',
            );
          }
          return null;
        },
      );
      final ApiAuthRepository repo = ApiAuthRepository(
        client: client,
        authState: authState,
        tokenStorage: storage,
        preferences: await SharedPreferences.getInstance(),
      );

      final RefreshOutcome outcome = await repo.refreshSession();

      expect(outcome, RefreshOutcome.success);
      expect(client.refreshAttempts, 2);
      expect(await storage.accessToken, 'new-access');
      expect(await storage.refreshToken, 'new-refresh');
    },
  );

  test(
    'refreshSession maps persistent INVALID_REFRESH_TOKEN to serverRejected',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SecureTokenStorage storage = SecureTokenStorage(
        storage: const FlutterSecureStorage(),
      );
      await storage.saveTokens(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
      );

      final _RefreshRetryApiClient client = _RefreshRetryApiClient(
        onRefresh: (_) => const AppError(
          code: 'INVALID_REFRESH_TOKEN',
          message: 'dead token',
        ),
      );
      final ApiAuthRepository repo = ApiAuthRepository(
        client: client,
        authState: AuthState(),
        tokenStorage: storage,
        preferences: await SharedPreferences.getInstance(),
      );

      final RefreshOutcome outcome = await repo.refreshSession();

      expect(outcome, RefreshOutcome.serverRejected);
      expect(client.refreshAttempts, 3);
    },
  );

  test(
    'refreshSession recovers when storage rotated during retry loop',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SecureTokenStorage storage = SecureTokenStorage(
        storage: const FlutterSecureStorage(),
      );
      await storage.saveTokens(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
      );

      final _RefreshRetryApiClient client = _RefreshRetryApiClient(
        onRefresh: (int attempt) {
          if (attempt < 3) {
            return const AppError(
              code: 'INVALID_REFRESH_TOKEN',
              message: 'stale during rotation race',
            );
          }
          return null;
        },
      );
      final ApiAuthRepository repo = ApiAuthRepository(
        client: client,
        authState: AuthState(),
        tokenStorage: storage,
        preferences: await SharedPreferences.getInstance(),
      );

      // Simulate background refresh rotating tokens while foreground retries fail.
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 50), () async {
          await storage.saveTokens(
            accessToken: 'parallel-access',
            refreshToken: 'parallel-refresh',
          );
        }),
      );

      final RefreshOutcome outcome = await repo.refreshSession();

      expect(outcome, RefreshOutcome.success);
      expect(client.refreshAttempts, 4);
      expect(await storage.accessToken, 'new-access');
      expect(await storage.refreshToken, 'new-refresh');
    },
  );
}
