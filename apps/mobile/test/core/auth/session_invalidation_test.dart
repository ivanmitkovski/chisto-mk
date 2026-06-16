import 'package:chisto_infrastructure/core/auth/session_invalidation.dart';
import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:feature_auth/src/domain/refresh_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  setUp(() {
    AppBootstrap.instance.authState.setAuthenticated(
      userId: 'u-session-invalidation',
      displayName: 'Tester',
      accessToken: 'token',
    );
    AppBootstrap.instance.apiClient.refreshSession = () async =>
        RefreshOutcome.serverRejected;
  });

  test('shouldHandle matches indicatesInvalidOrEndedSession', () {
    expect(SessionInvalidation.shouldHandle(AppError.unauthorized()), isTrue);
    expect(
      SessionInvalidation.shouldHandle(
        const AppError(code: 'SESSION_REVOKED', message: 'revoked'),
      ),
      isTrue,
    );
    expect(SessionInvalidation.shouldHandle(AppError.network()), isFalse);
  });

  test('fromError clears session after refresh is serverRejected', () async {
    await SessionInvalidation.fromError(AppError.unauthorized());
    expect(AppBootstrap.instance.authState.isAuthenticated, isFalse);
  });

  test('fromError keeps session when refresh succeeds', () async {
    AppBootstrap.instance.apiClient.refreshSession = () async =>
        RefreshOutcome.success;

    await SessionInvalidation.fromError(AppError.unauthorized());
    expect(AppBootstrap.instance.authState.isAuthenticated, isTrue);
  });

  test('fromError ignores non-session errors', () async {
    await SessionInvalidation.fromError(AppError.network());
    expect(AppBootstrap.instance.authState.isAuthenticated, isTrue);
  });

  test('force coalesces parallel invalidations', () async {
    await Future.wait(<Future<void>>[
      SessionInvalidation.force(),
      SessionInvalidation.force(),
      SessionInvalidation.force(),
    ]);
    expect(AppBootstrap.instance.authState.isAuthenticated, isFalse);
  });
}
