import 'dart:async';

/// Schedules outbox drain work. Default [InProcessBackgroundSubmitScheduler]
/// runs immediately on the current isolate (same as pre-interface behavior).
///
/// **Follow-up (native):** wire [PlatformBackgroundSubmitScheduler] using
/// `workmanager` on Android and `BGTaskScheduler` on iOS so uploads continue when
/// the app is backgrounded. Idempotency keys and SQLite rows already support resume.
abstract class BackgroundSubmitScheduler {
  /// Fire-and-forget: coordinator should call [scheduleDrain] instead of awaiting
  /// long-running work on the UI isolate for large uploads.
  void scheduleDrain(Future<void> Function() drain);
}

/// Current production behavior: drain runs on the calling isolate via microtask.
class InProcessBackgroundSubmitScheduler implements BackgroundSubmitScheduler {
  @override
  void scheduleDrain(Future<void> Function() drain) {
    unawaited(Future<void>.microtask(drain));
  }
}

/// Placeholder for a future WorkManager / BGTaskScheduler integration.
class PlatformBackgroundSubmitScheduler implements BackgroundSubmitScheduler {
  @override
  void scheduleDrain(Future<void> Function() drain) {
    // Intentionally identical to in-process until native plugins are added.
    InProcessBackgroundSubmitScheduler().scheduleDrain(drain);
  }
}
