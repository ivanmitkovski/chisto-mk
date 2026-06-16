import 'package:chisto_infrastructure/core/auth/background_session_refresh.dart';
import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:chisto_infrastructure/core/storage/secure_token_storage.dart';
import 'package:feature_auth/src/domain/refresh_outcome.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _BackgroundRefreshApiClient extends ApiClient {
  _BackgroundRefreshApiClient({required this.onRefresh})
    : super(
        config: AppConfig.dev,
        accessToken: () => null,
        onUnauthorized: (_) {},
      );

  final AppError? Function(int attempt) onRefresh;
  int refreshAttempts = 0;

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
          'accessToken': 'bg-access',
          'refreshToken': 'bg-refresh-rotated',
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

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'chisto_device_id': 'device-bg',
      'chisto_refresh_token': 'bg-refresh',
    });
  });

  test('retries INVALID_REFRESH_TOKEN before giving up', () async {
    final _BackgroundRefreshApiClient client = _BackgroundRefreshApiClient(
      onRefresh: (int attempt) {
        if (attempt < 2) {
          return const AppError(
            code: 'INVALID_REFRESH_TOKEN',
            message: 'stale',
          );
        }
        return null;
      },
    );
    final SecureTokenStorage storage = SecureTokenStorage();

    final RefreshOutcome outcome = await BackgroundSessionRefresh.tryRefresh(
      config: AppConfig.dev,
      tokenStorage: storage,
      clientOverride: client,
    );

    expect(outcome, RefreshOutcome.success);
    expect(client.refreshAttempts, 3);
    expect(await storage.accessToken, 'bg-access');
    client.dispose();
  });

  test(
    'returns transient when rotation race persists without server rejection',
    () async {
      final _BackgroundRefreshApiClient client = _BackgroundRefreshApiClient(
        onRefresh: (_) =>
            const AppError(code: 'INVALID_REFRESH_TOKEN', message: 'stale'),
      );
      final SecureTokenStorage storage = SecureTokenStorage();

      final RefreshOutcome outcome = await BackgroundSessionRefresh.tryRefresh(
        config: AppConfig.dev,
        tokenStorage: storage,
        clientOverride: client,
      );

      expect(outcome, RefreshOutcome.transient);
      expect(client.refreshAttempts, 3);
      client.dispose();
    },
  );
}
