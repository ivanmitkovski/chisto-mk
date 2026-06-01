import 'package:chisto_infrastructure/core/validation/macedonian_phone_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const MacedonianPhoneFormatter formatter = MacedonianPhoneFormatter();

  TextEditingValue apply(String oldText, String newText) {
    return formatter.formatEditUpdate(
      TextEditingValue(text: oldText),
      TextEditingValue(text: newText),
    );
  }

  group('MacedonianPhoneFormatter', () {
    test('formats up to 8 national digits with spaces', () {
      expect(apply('', '70123456').text, '70 123 456');
      expect(apply('', '70').text, '70');
      expect(apply('', '70123').text, '70 123');
    });

    test(
      'keeps only last 8 digits when pasting a longer number into empty field',
      () {
        expect(apply('', '3897012345678').text, '12 345 678');
      },
    );

    test(
      'keeps first 8 digits when input grows beyond 8 from non-empty field',
      () {
        expect(apply('70 123 456', '701234567').text, '70 123 456');
      },
    );

    test('blocks additional digits once 8 national digits are entered', () {
      final TextEditingValue full = apply('', '70123456');
      expect(full.text, '70 123 456');
      expect(
        formatter.formatEditUpdate(
          full,
          const TextEditingValue(text: '701234567'),
        ),
        full,
      );
    });

    test('places cursor at end of formatted text', () {
      final TextEditingValue value = apply('', '7012');
      expect(value.selection, const TextSelection.collapsed(offset: 5));
    });
  });
}
