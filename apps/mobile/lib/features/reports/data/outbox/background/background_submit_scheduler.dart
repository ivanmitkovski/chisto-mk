import 'dart:async';

/// Schedules outbox drain work. Default [InProcessBackgroundSubmitScheduler]
/// runs immediately on the current isolate (same as pre-interface behavior).
///
/// **Native:** [PlatformBackgroundSubmitScheduler] (see
/// `platform_background_submit_scheduler.dart`) registers a `workmanager` one-off
/// drain in addition to the in-process microtask. Idempotency keys and SQLite
/// rows support resume across process restarts.
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
