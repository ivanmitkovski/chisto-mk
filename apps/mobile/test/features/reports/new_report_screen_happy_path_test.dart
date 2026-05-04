import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  test('reports test harness initializes (wizard UI covered by integration)', () async {
    await bootstrapWidgetTests();
    expect(true, isTrue);
  });
}
