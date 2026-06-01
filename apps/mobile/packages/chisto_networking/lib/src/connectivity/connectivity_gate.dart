import 'package:chisto_networking/src/connectivity/app_connectivity.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

export 'app_connectivity.dart';

/// Backward-compatible alias — prefer [AppConnectivity] in new code.
class ConnectivityGate {
  ConnectivityGate._();

  static Future<List<ConnectivityResult>> Function() get check =>
      AppConnectivity.check;

  static set check(Future<List<ConnectivityResult>> Function() fn) {
    AppConnectivity.check = fn;
  }

  static Stream<List<ConnectivityResult>> Function() get watch =>
      AppConnectivity.watch;

  static set watch(Stream<List<ConnectivityResult>> Function() fn) {
    AppConnectivity.watch = fn;
  }

  static bool isOnline(List<ConnectivityResult> results) =>
      AppConnectivity.isOnline(results);

  static bool isOffline(List<ConnectivityResult> results) =>
      AppConnectivity.isOffline(results);
}
