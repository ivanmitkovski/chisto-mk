import 'dart:async';

/// Coalesces concurrent invocations of an async operation into a single
/// in-flight Future. Useful for guarding tap-spam on submit/send/sign-in
/// buttons where double-fire would create duplicate work (and duplicate
/// snacks/navigations).
///
/// Usage:
/// ```dart
/// final SingleFlight<Result> _submit = SingleFlight<Result>();
///
/// Future<Result> submit() => _submit.run(() async {
///   return await api.send(payload);
/// });
/// ```
///
/// Callers can also observe [isRunning] to disable UI affordances while a
/// request is in flight without sprinkling separate `_submitting` flags.
class SingleFlight<T> {
  SingleFlight();

  Future<T>? _inFlight;

  bool get isRunning => _inFlight != null;

  /// If a previous invocation is still pending, this returns the same Future
  /// (subsequent callers receive the same result/error). Otherwise it starts
  /// a new operation and stores its Future until completion.
  ///
  /// The error of a failing task is delivered through the returned Future to
  /// every awaiter. We funnel it through an internal [Completer] so each
  /// caller's await counts as a real "handle" — without this, the
  /// `unhandled async error` zone listener fires when the second caller
  /// awaits after the future has already errored.
  Future<T> run(Future<T> Function() task) {
    final Future<T>? existing = _inFlight;
    if (existing != null) {
      return existing;
    }
    final Completer<T> completer = Completer<T>();
    final Future<T> shared = completer.future;
    _inFlight = shared;
    // Always observe the broadcast future (.catchError no-op) so the original
    // task error is considered "handled" by the SingleFlight even when no
    // caller awaits in time.
    shared.then<void>((T _) {}, onError: (Object _) {});
    () async {
      try {
        completer.complete(await task());
      } on Object catch (e, st) {
        completer.completeError(e, st);
      } finally {
        if (identical(_inFlight, shared)) {
          _inFlight = null;
        }
      }
    }();
    return shared;
  }
}
