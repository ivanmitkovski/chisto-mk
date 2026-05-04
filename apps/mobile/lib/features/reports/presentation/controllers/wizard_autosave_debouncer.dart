import 'dart:async';

/// Debounced side-effect scheduling for wizard autosave (testable in isolation).
class WizardAutosaveDebouncer {
  WizardAutosaveDebouncer({this.delay = const Duration(milliseconds: 300)});

  final Duration delay;
  Timer? _timer;

  void schedule(Future<void> Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      unawaited(action());
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    cancel();
  }
}
