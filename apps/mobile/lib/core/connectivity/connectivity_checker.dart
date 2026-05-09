import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin abstraction over [Connectivity] for tests and map offline logic.
abstract class ConnectivityChecker {
  const ConnectivityChecker();

  /// True when the device has no usable data path (no Wi‑Fi / cellular / Ethernet / VPN).
  Future<bool> isOffline();

  /// Default implementation using [connectivity_plus].
  factory ConnectivityChecker.system() = _SystemConnectivityChecker;
}

/// Fixed outcome for unit tests.
class FixedConnectivityChecker extends ConnectivityChecker {
  const FixedConnectivityChecker({required this.offline});

  final bool offline;

  @override
  Future<bool> isOffline() async => offline;
}

class _SystemConnectivityChecker extends ConnectivityChecker {
  _SystemConnectivityChecker() : _connectivity = Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> isOffline() async {
    final List<ConnectivityResult> results =
        await _connectivity.checkConnectivity();
    if (results.isEmpty) {
      return true;
    }
    return results.every((ConnectivityResult r) => r == ConnectivityResult.none);
  }
}
