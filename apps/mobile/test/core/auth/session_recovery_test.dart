import 'package:chisto_infrastructure/core/auth/session_recovery.dart';
import 'package:chisto_infrastructure/core/auth/session_teardown_reason.dart';
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
      userId: 'u-session-recovery',
      displayName: 'Tester',
      accessToken: 'token',
    );
    AppBootstrap.instance.apiClient.refreshSession = () async =>
        RefreshOutcome.success;
  });

  test('refreshBeforeInvalidate keeps session when refresh succeeds', () async {
    final bool invalidated = await SessionRecovery.refreshBeforeInvalidate(
      reason: SessionTeardownReason.sessionInvalidationUi,
    );
    expect(invalidated, isFalse);
    expect(AppBootstrap.instance.authState.isAuthenticated, isTrue);
  });

  test(
    'refreshBeforeInvalidate keeps session on transient refresh failure',
    () async {
      AppBootstrap.instance.apiClient.refreshSession = () async =>
          RefreshOutcome.transient;

      final bool invalidated = await SessionRecovery.refreshBeforeInvalidate(
        reason: SessionTeardownReason.resumeRefreshRejected,
        delayedRetry: Duration.zero,
      );
      expect(invalidated, isFalse);
      expect(AppBootstrap.instance.authState.isAuthenticated, isTrue);
    },
  );

  test(
    'refreshBeforeInvalidate clears session when refresh is serverRejected',
    () async {
      AppBootstrap.instance.apiClient.refreshSession = () async =>
          RefreshOutcome.serverRejected;

      final bool invalidated = await SessionRecovery.refreshBeforeInvalidate(
        reason: SessionTeardownReason.proactiveRefreshRejected,
        delayedRetry: Duration.zero,
      );
      expect(invalidated, isTrue);
      expect(AppBootstrap.instance.authState.isAuthenticated, isFalse);
    },
  );
}
