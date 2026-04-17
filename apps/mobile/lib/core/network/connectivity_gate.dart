import 'package:connectivity_plus/connectivity_plus.dart';

/// Indirection so widget tests can stub [checkConnectivity] without platform fakes.
class ConnectivityGate {
  ConnectivityGate._();

  static Future<List<ConnectivityResult>> Function() check =
      () => Connectivity().checkConnectivity();
}
