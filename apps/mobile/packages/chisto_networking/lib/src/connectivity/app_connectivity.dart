import 'package:connectivity_plus/connectivity_plus.dart';

/// Single source of truth for reachability across the app.
///
/// [Connectivity.checkConnectivity] may return an empty list before the platform
/// reports a path. **Empty means unknown — treat as online** (optimistic) so
/// cold start, outbox drains, map sync, and save flows are not blocked while
/// the OS is still resolving connectivity.
class AppConnectivity {
  AppConnectivity._();

  /// Indirection so widget tests can stub connectivity without platform fakes.
  static Future<List<ConnectivityResult>> Function() check = () =>
      Connectivity().checkConnectivity();

  static Stream<List<ConnectivityResult>> Function() watch = () =>
      Connectivity().onConnectivityChanged;

  static bool isOnline(List<ConnectivityResult> results) {
    return results.isEmpty ||
        results.any((ConnectivityResult r) => r != ConnectivityResult.none);
  }

  static bool isOffline(List<ConnectivityResult> results) => !isOnline(results);
}
