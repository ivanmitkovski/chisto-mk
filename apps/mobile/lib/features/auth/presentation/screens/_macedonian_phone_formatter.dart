import 'package:flutter/services.dart';

String formatMacedonianLocalPhone(String digits) {
  if (digits.isEmpty) {
    return '';
  }
  // `digits` here is expected to be at most 8 characters.
  final String clipped = digits.length > 8 ? digits.substring(0, 8) : digits;

  if (clipped.length <= 2) {
    return clipped;
  }
  if (clipped.length <= 5) {
    return '${clipped.substring(0, 2)} ${clipped.substring(2)}';
  }
  return '${clipped.substring(0, 2)} ${clipped.substring(2, 5)} ${clipped.substring(5)}';
}

class MacedonianPhoneFormatter extends TextInputFormatter {
  const MacedonianPhoneFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final String oldDigits = oldValue.text.replaceAll(RegExp(r'\D'), '');
    final String newDigits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // If we already have 8 digits and the user is trying to add more,
    // ignore the new input so existing digits are not overridden.
    if (oldDigits.length >= 8 && newDigits.length > oldDigits.length) {
      return oldValue;
    }

    String effectiveDigits = newDigits;

    // Special case: user pastes a full international number into an empty field.
    // Take the last 8 digits so "+38971 234 567" still becomes "71 234 567".
    if (oldDigits.isEmpty && newDigits.length > 8) {
      effectiveDigits = newDigits.substring(newDigits.length - 8);
    } else if (newDigits.length > 8) {
      // For normal typing after the first input, clamp to the first 8 digits.
      effectiveDigits = newDigits.substring(0, 8);
    }

    final String formatted = formatMacedonianLocalPhone(effectiveDigits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

