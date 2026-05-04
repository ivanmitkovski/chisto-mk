import 'dart:async';

/// Coalesces bursty owner-socket events into a single list refresh.
final class ReportsListRealtimeCoalescer {
  ReportsListRealtimeCoalescer({
    required Duration debounce,
    required void Function() onRefresh,
  }) : _debounce = debounce,
       _onRefresh = onRefresh;

  final Duration _debounce;
  final void Function() _onRefresh;
  Timer? _timer;

  void schedule() {
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      _timer = null;
      _onRefresh();
    });
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
