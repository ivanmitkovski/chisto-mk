import 'package:chisto_infrastructure/core/connectivity/app_connectivity.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConnectivity.isOnline', () {
    test('empty list is unknown and treated as online', () {
      expect(AppConnectivity.isOnline(<ConnectivityResult>[]), isTrue);
      expect(AppConnectivity.isOffline(<ConnectivityResult>[]), isFalse);
    });

    test('none only is offline', () {
      expect(
        AppConnectivity.isOnline(<ConnectivityResult>[ConnectivityResult.none]),
        isFalse,
      );
    });

    test('wifi or mobile is online', () {
      expect(
        AppConnectivity.isOnline(<ConnectivityResult>[ConnectivityResult.wifi]),
        isTrue,
      );
      expect(
        AppConnectivity.isOnline(<ConnectivityResult>[
          ConnectivityResult.mobile,
        ]),
        isTrue,
      );
    });

    test('none mixed with wifi is online', () {
      expect(
        AppConnectivity.isOnline(<ConnectivityResult>[
          ConnectivityResult.none,
          ConnectivityResult.wifi,
        ]),
        isTrue,
      );
    });
  });
}
