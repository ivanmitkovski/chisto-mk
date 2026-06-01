import 'package:chisto_infrastructure/core/validation/password_strength.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computePasswordStrength', () {
    test('returns none for empty input', () {
      expect(computePasswordStrength(''), PasswordStrength.none);
      expect(computePasswordStrength('   '), PasswordStrength.none);
    });

    test('returns weak when shorter than 8 characters', () {
      expect(computePasswordStrength('abc1'), PasswordStrength.weak);
    });

    test('returns weak without both letters and numbers', () {
      expect(computePasswordStrength('abcdefgh'), PasswordStrength.weak);
      expect(computePasswordStrength('12345678'), PasswordStrength.weak);
    });

    test('returns weak for common patterns and repeated characters', () {
      expect(computePasswordStrength('password1'), PasswordStrength.weak);
      expect(computePasswordStrength('aaaaaaaa'), PasswordStrength.weak);
    });

    test('returns fair for valid 8–11 character passwords', () {
      expect(computePasswordStrength('validpass1'), PasswordStrength.fair);
    });

    test('returns strong for long passwords with uppercase or symbols', () {
      expect(computePasswordStrength('ValidPass123'), PasswordStrength.strong);
      expect(computePasswordStrength('longpass!234'), PasswordStrength.strong);
    });
  });
}
