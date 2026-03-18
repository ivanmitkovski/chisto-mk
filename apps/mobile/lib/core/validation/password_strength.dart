enum PasswordStrength {
  none,
  weak,
  fair,
  strong,
}

const List<String> _weakPatterns = <String>[
  'password',
  'password1',
  '12345678',
  'qwerty123',
  'abc12345',
  'letmein',
  'welcome',
  'admin123',
  'changeme',
];

PasswordStrength computePasswordStrength(String password) {
  final String s = password.trim();
  if (s.isEmpty) return PasswordStrength.none;
  if (s.length < 8) return PasswordStrength.weak;
  final bool hasLetter = s.contains(RegExp(r'[a-zA-Z]'));
  final bool hasNumber = s.contains(RegExp(r'[0-9]'));
  if (!hasLetter || !hasNumber) return PasswordStrength.weak;
  final String lower = s.toLowerCase();
  if (_weakPatterns.any((String p) => lower == p || lower.contains(p))) {
    return PasswordStrength.weak;
  }
  if (RegExp(r'^(.)\1*$').hasMatch(s)) return PasswordStrength.weak;
  if (s.length >= 12 && (s.contains(RegExp(r'[A-Z]')) || s.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')))) {
    return PasswordStrength.strong;
  }
  return PasswordStrength.fair;
}
