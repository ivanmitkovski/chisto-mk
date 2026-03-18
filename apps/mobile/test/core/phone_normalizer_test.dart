import 'package:chisto_mobile/core/validation/phone_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeToE164', () {
    test('converts 8-digit local number', () {
      expect(normalizeToE164('70123456'), equals('+38970123456'));
    });

    test('strips spaces from formatted local number', () {
      expect(normalizeToE164('70 123 456'), equals('+38970123456'));
    });

    test('strips leading zero', () {
      expect(normalizeToE164('070123456'), equals('+38970123456'));
    });

    test('handles full E.164 with spaces', () {
      expect(normalizeToE164('+389 70 123 456'), equals('+38970123456'));
    });

    test('handles full E.164 without spaces', () {
      expect(normalizeToE164('+38970123456'), equals('+38970123456'));
    });

    test('handles dashes and parentheses', () {
      expect(normalizeToE164('70-123-456'), equals('+38970123456'));
    });
  });
}
