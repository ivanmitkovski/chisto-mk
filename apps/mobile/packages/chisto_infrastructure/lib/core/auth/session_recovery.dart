import 'dart:async';
import 'dart:math' as math;

import 'package:chisto_infrastructure/core/auth/session_teardown_reason.dart';
import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:feature_auth/src/domain/refresh_outcome.dart';

/// Attempts token refresh before tearing down a session.
///
/// Used by resume refresh, proactive refresh, UI invalidation, and realtime
/// auth rejection paths so rotation races and brief ALB task switches can
/// recover without signing the user out.
abstract final class SessionRecovery {
  static final math.Random _random = math.Random();

  /// Returns `true` when the session was invalidated locally.
  static Future<bool> refreshBeforeInvalidate({
    required SessionTeardownReason reason,
    int? observedEpoch,
    Duration? delayedRetry,
  }) async {
    final AppBootstrap? bootstrap = tryReadRoot(appBootstrapProvider);
    if (bootstrap == null || !bootstrap.isInitialized) {
      return false;
    }
    if (!bootstrap.authState.isAuthenticated) {
      return false;
    }
    if (observedEpoch != null &&
        bootstrap.authState.sessionEpoch != observedEpoch) {
      return false;
    }

    RefreshOutcome outcome = await bootstrap.apiClient.refreshSessionQueued();
    if (_shouldKeepSession(outcome)) {
      return false;
    }

    if (delayedRetry != null) {
      await Future<void>.delayed(delayedRetry);
      if (observedEpoch != null &&
          bootstrap.authState.sessionEpoch != observedEpoch) {
        return false;
      }
      if (!bootstrap.authState.isAuthenticated) {
        return false;
      }
      outcome = await bootstrap.apiClient.refreshSessionQueued();
      if (_shouldKeepSession(outcome)) {
        return false;
      }
    }

    if (outcome != RefreshOutcome.serverRejected) {
      return false;
    }

    await readRoot(
      authRepositoryProvider,
    ).invalidateLocalSession(observedEpoch: observedEpoch, reason: reason);
    return true;
  }

  static bool _shouldKeepSession(RefreshOutcome outcome) {
    return outcome == RefreshOutcome.success ||
        outcome == RefreshOutcome.transient;
  }

  /// Jittered delay for resume/realtime recovery (500–1500ms).
  static Duration resumeDelayedRetry() {
    return Duration(milliseconds: 500 + _random.nextInt(1000));
  }
}
