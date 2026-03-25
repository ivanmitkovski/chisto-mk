import 'package:chisto_mobile/core/validation/input_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InputValidators', () {
    group('validateRequired', () {
      test('returns null for non-empty value', () {
        expect(InputValidators.validateRequired('hello', 'Field'), isNull);
        expect(InputValidators.validateRequired('  text  ', 'Field'), isNull);
      });

      test('returns error for null or empty', () {
        expect(
          InputValidators.validateRequired(null, 'Name'),
          equals('Name is required'),
        );
        expect(
          InputValidators.validateRequired('', 'Email'),
          equals('Email is required'),
        );
        expect(
          InputValidators.validateRequired('   ', 'Phone'),
          equals('Phone is required'),
        );
      });
    });

    group('validatePhone', () {
      test('returns null for valid phone numbers', () {
        expect(InputValidators.validatePhone('+38970123456'), isNull);
        expect(InputValidators.validatePhone('070123456'), isNull);
        expect(InputValidators.validatePhone('+1 555 123 4567'), isNull);
        expect(InputValidators.validatePhone('12345678'), isNull);
      });

      test('returns error for empty', () {
        expect(
          InputValidators.validatePhone(null),
          equals('Phone number is required'),
        );
        expect(
          InputValidators.validatePhone(''),
          equals('Phone number is required'),
        );
        expect(
          InputValidators.validatePhone('   '),
          equals('Phone number is required'),
        );
      });

      test('returns error for invalid format', () {
        expect(
          InputValidators.validatePhone('abc'),
          equals('Enter a valid phone number'),
        );
        expect(
          InputValidators.validatePhone('123'), // too short (< 8)
          equals('Enter a valid phone number'),
        );
        expect(
          InputValidators.validatePhone('123456789012345678'), // too long (> 17)
          equals('Enter a valid phone number'),
        );
      });
    });

    group('validateEmail', () {
      test('returns null for valid emails', () {
        expect(InputValidators.validateEmail('user@example.com'), isNull);
        expect(InputValidators.validateEmail('test.user@domain.co'), isNull);
        expect(InputValidators.validateEmail('a@b.c'), isNull);
      });

      test('returns error for empty', () {
        expect(
          InputValidators.validateEmail(null),
          equals('Email is required'),
        );
        expect(
          InputValidators.validateEmail(''),
          equals('Email is required'),
        );
        expect(
          InputValidators.validateEmail('   '),
          equals('Email is required'),
        );
      });

      test('returns error for invalid format', () {
        expect(
          InputValidators.validateEmail('invalid'),
          equals('Enter a valid email'),
        );
        expect(
          InputValidators.validateEmail('missing@domain'),
          equals('Enter a valid email'),
        );
        expect(
          InputValidators.validateEmail('@domain.com'),
          equals('Enter a valid email'),
        );
      });
    });

    group('validatePassword', () {
      test('returns null for valid password', () {
        expect(InputValidators.validatePassword('password1'), isNull);
        expect(InputValidators.validatePassword('abc12345'), isNull);
        expect(InputValidators.validatePassword('longpassword1'), isNull);
      });

      test('returns error for empty', () {
        expect(
          InputValidators.validatePassword(null),
          equals('Password is required'),
        );
        expect(
          InputValidators.validatePassword(''),
          equals('Password is required'),
        );
        expect(
          InputValidators.validatePassword('   '),
          equals('Password is required'),
        );
      });

      test('returns error when shorter than 8 characters', () {
        expect(
          InputValidators.validatePassword('short'),
          equals('Password must be at least 8 characters'),
        );
        expect(
          InputValidators.validatePassword('1234567'),
          equals('Password must be at least 8 characters'),
        );
      });
    });
  });
}
