/// Full display string including country code (e.g. "+389 70 123 456").
/// Use for labels or fields that do not have a fixed "+389" prefix.
String formatPhoneForDisplay(String? value) {
  if (value == null || value.trim().isEmpty) return '—';
  final String digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '—';
  final String local = digits.length >= 8 ? digits.substring(digits.length - 8) : digits;
  if (local.length <= 2) return local;
  if (local.length <= 5) return '+389 ${local.substring(0, 2)} ${local.substring(2)}';
  return '+389 ${local.substring(0, 2)} ${local.substring(2, 5)} ${local.substring(5)}';
}

/// National part only for use in fields with [prefixFixedText: '+389'].
/// Returns e.g. "70 123 456" so the UI shows "+389" + this, not "+389 +389 ...".
String formatPhoneNationalPart(String? value) {
  if (value == null || value.trim().isEmpty) return '';
  final String digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  final String local = digits.length >= 8 ? digits.substring(digits.length - 8) : digits;
  if (local.length <= 2) return local;
  if (local.length <= 5) return '${local.substring(0, 2)} ${local.substring(2)}';
  return '${local.substring(0, 2)} ${local.substring(2, 5)} ${local.substring(5)}';
}
