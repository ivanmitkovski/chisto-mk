import 'dart:async';

import 'package:chisto_infrastructure/core/auth/session_recovery.dart';
import 'package:chisto_infrastructure/core/auth/session_teardown_reason.dart';
import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:feature_auth/src/data/access_token_expiry.dart';
import 'package:flutter/widgets.dart';

/// Refreshes the access token when the app returns to foreground with an
/// expired or near-expired JWT (timers are suspended while backgrounded).
class SessionResumeRefreshLifecycle with WidgetsBindingObserver {
  SessionResumeRefreshLifecycle();

  Future<void>? _refreshInFlight;

  void register() {
    WidgetsBinding.instance.addObserver(this);
  }

  void unregister() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    unawaited(_refreshIfNeededOnResume());
  }

  Future<void> _refreshIfNeededOnResume() async {
    final AppBootstrap? bootstrap = tryReadRoot(appBootstrapProvider);
    if (bootstrap == null || !bootstrap.isInitialized) {
      return;
    }
    if (!bootstrap.authState.isAuthenticated) {
      return;
    }
    final String? token = bootstrap.authState.accessToken;
    if (token == null || token.isEmpty) {
      return;
    }
    if (!accessTokenNeedsRefreshSoon(token)) {
      return;
    }

    final Future<void>? inFlight = _refreshInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final Future<void> started = _runRefresh(bootstrap);
    _refreshInFlight = started;
    try {
      await started;
    } finally {
      if (identical(_refreshInFlight, started)) {
        _refreshInFlight = null;
      }
    }
  }

  Future<void> _runRefresh(AppBootstrap bootstrap) async {
    try {
      await SessionRecovery.refreshBeforeInvalidate(
        reason: SessionTeardownReason.resumeRefreshRejected,
        delayedRetry: SessionRecovery.resumeDelayedRetry(),
      );
    } on Object catch (e, st) {
      AppLog.warn('resume token refresh failed', error: e, stackTrace: st);
    }
  }
}
