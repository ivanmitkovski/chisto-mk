import 'package:chisto_mobile/core/logging/app_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppLog.verbose does not throw', () {
    expect(() => AppLog.verbose('smoke'), returnsNormally);
  });

  test('AppLog.warn does not throw', () {
    expect(() => AppLog.warn('smoke'), returnsNormally);
  });
}
