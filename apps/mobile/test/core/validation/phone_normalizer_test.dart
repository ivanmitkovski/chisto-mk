import 'package:chisto_infrastructure/core/validation/phone_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeToE164', () {
    test('handles already-canonical', () {
      expect(normalizeToE164('+38970123456'), '+38970123456');
      expect(normalizeToE164('+389 70 123 456'), '+38970123456');
    });

    test('handles local format with leading zero', () {
      expect(normalizeToE164('070 123 456'), '+38970123456');
      expect(normalizeToE164('070123456'), '+38970123456');
    });

    test('handles bare national number', () {
      expect(normalizeToE164('70 123 456'), '+38970123456');
      expect(normalizeToE164('70123456'), '+38970123456');
    });

    test('handles international dialing prefix', () {
      expect(normalizeToE164('00389 70 123 456'), '+38970123456');
      expect(normalizeToE164('00389701234'), '+389701234');
    });

    test('handles country code without plus', () {
      expect(normalizeToE164('389 70 123 456'), '+38970123456');
    });

    test('collapses redundant leading zero after +389', () {
      expect(normalizeToE164('+389070123456'), '+38970123456');
    });

    test('returns empty for empty input', () {
      expect(normalizeToE164(''), '');
      expect(normalizeToE164('   '), '');
    });

    test('strips letters and stray punctuation', () {
      expect(normalizeToE164('+389 (70) 123-456'), '+38970123456');
      expect(normalizeToE164('phone: 070 123 456'), '+38970123456');
    });
  });
}
