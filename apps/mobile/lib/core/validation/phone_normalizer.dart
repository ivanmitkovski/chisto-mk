/// Normalizes a Macedonian local phone number to E.164 format.
///
/// Input examples: "70 123 456", "070123456", "+389 70 123 456"
/// Output: "+38970123456"
String normalizeToE164(String raw) {
  final String digits = raw.replaceAll(RegExp(r'[^\d+]'), '');

  if (digits.startsWith('+389')) {
    return '+389${digits.substring(4)}';
  }

  final String localDigits = digits.startsWith('0') ? digits.substring(1) : digits;
  return '+389$localDigits';
}
