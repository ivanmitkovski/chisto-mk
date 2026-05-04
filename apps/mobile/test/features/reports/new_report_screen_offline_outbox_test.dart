import 'package:chisto_mobile/core/network/connectivity_gate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  test('ConnectivityGate can be forced offline for outbox tests', () async {
    await bootstrapWidgetTests();
    final Future<List<ConnectivityResult>> Function() saved = ConnectivityGate.check;
    ConnectivityGate.check =
        () async => <ConnectivityResult>[ConnectivityResult.none];
    final List<ConnectivityResult> r = await ConnectivityGate.check();
    expect(ConnectivityGate.isOnline(r), isFalse);
    ConnectivityGate.check = saved;
  });
}
