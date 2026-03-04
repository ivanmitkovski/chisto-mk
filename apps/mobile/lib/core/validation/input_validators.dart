class InputValidators {
  const InputValidators._();

  static String? validateRequired(String? value, String fieldLabel) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldLabel is required';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Phone number is required';
    }

    final RegExp pattern = RegExp(r'^\+?[0-9 ]{8,17}$');
    if (!pattern.hasMatch(trimmed)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Email is required';
    }

    final RegExp pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(trimmed)) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Password is required';
    }
    if (trimmed.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }
}
