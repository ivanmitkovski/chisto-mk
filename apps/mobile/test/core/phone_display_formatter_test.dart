import 'package:chisto_mobile/core/validation/phone_display_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatPhoneForDisplay', () {
    test('formats E164 to full display with country code', () {
      expect(formatPhoneForDisplay('+38970123456'), equals('+389 70 123 456'));
    });
    test('returns em dash for null or empty', () {
      expect(formatPhoneForDisplay(null), equals('—'));
      expect(formatPhoneForDisplay(''), equals('—'));
    });
  });

  group('formatPhoneNationalPart', () {
    test('returns national part only for prefix fields', () {
      expect(formatPhoneNationalPart('+38970123456'), equals('70 123 456'));
    });
    test('handles E164 with spaces', () {
      expect(formatPhoneNationalPart('+389 70 123 456'), equals('70 123 456'));
    });
    test('returns empty for null or empty', () {
      expect(formatPhoneNationalPart(null), equals(''));
      expect(formatPhoneNationalPart(''), equals(''));
    });
    test('extracts last 8 digits when extra digits present', () {
      expect(formatPhoneNationalPart('38970123456'), equals('70 123 456'));
    });
  });
}
