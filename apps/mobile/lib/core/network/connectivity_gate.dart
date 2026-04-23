import 'package:connectivity_plus/connectivity_plus.dart';

/// Indirection so widget tests can stub connectivity without platform fakes.
class ConnectivityGate {
  ConnectivityGate._();

  static Future<List<ConnectivityResult>> Function() check =
      () => Connectivity().checkConnectivity();

  static Stream<List<ConnectivityResult>> Function() watch =
      () => Connectivity().onConnectivityChanged;

  /// [checkConnectivity] may return an empty list before the platform reports;
  /// treat that as online (same contract as extend-end / edit-event save paths).
  static bool isOnline(List<ConnectivityResult> results) {
    return results.isEmpty ||
        results.any((ConnectivityResult e) => e != ConnectivityResult.none);
  }
}
