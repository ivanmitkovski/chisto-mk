import 'package:chisto_infrastructure/core/location/macedonia_bounds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isWithinMacedonia', () {
    test('accepts Skopje city center', () {
      expect(isWithinMacedonia(41.9981, 21.4254), isTrue);
    });

    test('rejects coordinates outside the country', () {
      expect(isWithinMacedonia(48.8566, 2.3522), isFalse);
    });
  });
}
