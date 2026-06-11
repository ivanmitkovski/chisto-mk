import 'package:chisto_infrastructure/core/auth/session_recovery.dart';
import 'package:chisto_infrastructure/core/auth/session_teardown_reason.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';

/// Central entry point for clearing a locally invalid session.
///
/// Navigation to sign-in is owned by [AuthSessionScope] after
/// [AuthState] becomes unauthenticated — callers must not navigate here.
abstract final class SessionInvalidation {
  static Future<void>? _inFlight;

  static bool shouldHandle(AppError error) =>
      error.indicatesInvalidOrEndedSession;

  static Future<void> fromError(AppError error, {int? observedEpoch}) {
    if (!shouldHandle(error)) {
      return Future<void>.value();
    }
    return SessionRecovery.refreshBeforeInvalidate(
      reason: SessionTeardownReason.sessionInvalidationUi,
      observedEpoch: observedEpoch,
      delayedRetry: SessionRecovery.resumeDelayedRetry(),
    );
  }

  static Future<void> force({int? observedEpoch}) {
    final Future<void>? inFlight = _inFlight;
    if (inFlight != null) {
      return inFlight;
    }
    final Future<void> started = readRoot(
      authRepositoryProvider,
    ).invalidateLocalSession(
      observedEpoch: observedEpoch,
      reason: SessionTeardownReason.forced,
    );
    _inFlight = started;
    return started.whenComplete(() {
      if (identical(_inFlight, started)) {
        _inFlight = null;
      }
    });
  }
}
