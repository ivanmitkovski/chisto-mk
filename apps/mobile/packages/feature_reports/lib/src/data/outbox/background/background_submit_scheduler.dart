import 'dart:async';

/// Schedules outbox drain work. Default [InProcessBackgroundSubmitScheduler]
/// runs immediately on the current isolate (same as pre-interface behavior).
///
/// **Native:** [PlatformBackgroundSubmitScheduler] (see
/// `platform_background_submit_scheduler.dart`) registers a `workmanager` one-off
/// drain in addition to the in-process microtask. Idempotency keys and SQLite
/// rows support resume across process restarts.
// ignore: one_member_abstracts, intentional injectable port
abstract class BackgroundSubmitScheduler {
  /// Fire-and-forget: coordinator should call [scheduleDrain] instead of awaiting
  /// long-running work on the UI isolate for large uploads.
  ///
  /// When [requestNativeFollowUp] is true, [PlatformBackgroundSubmitScheduler]
  /// also registers a Workmanager one-off (offline/cooldown deferral or app
  /// background) so work can resume outside the foreground isolate.
  void scheduleDrain(
    Future<void> Function() drain, {
    bool requestNativeFollowUp = false,
  });
}

/// Current production behavior: drain runs on the calling isolate via microtask.
class InProcessBackgroundSubmitScheduler implements BackgroundSubmitScheduler {
  @override
  void scheduleDrain(
    Future<void> Function() drain, {
    bool requestNativeFollowUp = false,
  }) {
    unawaited(Future<void>.microtask(drain));
  }
}
