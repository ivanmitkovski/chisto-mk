import 'package:chisto_core/chisto_core.dart';
import 'package:flutter/services.dart';

export 'package:chisto_core/chisto_core.dart' show formatMacedonianLocalPhone;

class MacedonianPhoneFormatter extends TextInputFormatter {
  const MacedonianPhoneFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String oldDigits = oldValue.text.replaceAll(RegExp(r'\D'), '');
    final String newDigits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (oldDigits.length >= 8 && newDigits.length > oldDigits.length) {
      return oldValue;
    }

    String effectiveDigits = newDigits;
    if (oldDigits.isEmpty && newDigits.length > 8) {
      effectiveDigits = newDigits.substring(newDigits.length - 8);
    } else if (newDigits.length > 8) {
      effectiveDigits = newDigits.substring(0, 8);
    }

    final String formatted = formatMacedonianLocalPhone(effectiveDigits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
