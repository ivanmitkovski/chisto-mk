/// Normalizes a Macedonian phone number to E.164 format (`+389XXXXXXXX`).
///
/// Accepts every common citizen input variant:
///   "70 123 456"        → "+38970123456"
///   "070 123 456"       → "+38970123456"
///   "+389 70 123 456"   → "+38970123456"
///   "00389 70 123 456"  → "+38970123456"
///   "389 70 123 456"    → "+38970123456"
///   "+3890701234"       → "+389701234"   (collapses redundant leading "0")
///
/// Returns the cleaned string even when it could not be parsed as MK so the
/// caller can still surface a validation error against the raw value.
String normalizeToE164(String raw) {
  final String digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
  if (digits.isEmpty) return '';

  String local = digits;
  if (local.startsWith('+389')) {
    local = local.substring(4);
  } else if (local.startsWith('00389')) {
    local = local.substring(5);
  } else if (local.startsWith('389')) {
    local = local.substring(3);
  }
  // Collapse a single leading "0" left over from a local-trunk prefix.
  while (local.startsWith('0')) {
    local = local.substring(1);
  }
  if (local.isEmpty) return '';
  return '+389$local';
}
