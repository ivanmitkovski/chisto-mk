import 'package:chisto_infrastructure/l10n/app_localizations.dart';

/// Form validators for auth flows — messages from [AppLocalizations].
class AuthValidators {
  AuthValidators._();

  static String? requiredField(
    AppLocalizations l10n,
    String? value,
    String fieldLabel,
  ) {
    if (value == null || value.trim().isEmpty) {
      return l10n.authValidationFieldRequired(fieldLabel);
    }
    return null;
  }

  static String? email(AppLocalizations l10n, String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return l10n.authValidationEmailRequired;
    }
    final RegExp pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(trimmed)) {
      return l10n.authValidationEmailInvalid;
    }
    return null;
  }

  static String? password(AppLocalizations l10n, String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return l10n.authValidationPasswordRequired;
    }
    if (trimmed.length < 8) {
      return l10n.authValidationPasswordMinLength;
    }
    if (!RegExp(r'\d').hasMatch(trimmed)) {
      return l10n.authValidationPasswordNeedNumber;
    }
    if (!RegExp('[A-Za-z]').hasMatch(trimmed)) {
      return l10n.authValidationPasswordNeedLetter;
    }
    return null;
  }

  static String? fullName(AppLocalizations l10n, String? value) {
    final String? required = requiredField(l10n, value, l10n.authFieldFullName);
    if (required != null) return required;
    final List<String> parts = value!
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.length < 2) {
      return l10n.authValidationFullNameTwoParts;
    }
    return null;
  }

  static String? macedonianPhone(AppLocalizations l10n, String? value) {
    final String digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return l10n.authValidationPhoneRequired;
    }
    if (digits.length != 8) {
      return l10n.authValidationPhoneDigits;
    }
    return null;
  }

  static String? Function(String?) confirmPassword(
    AppLocalizations l10n,
    String password,
  ) {
    return (String? value) {
      final String trimmed = value?.trim() ?? '';
      if (trimmed.isEmpty) {
        return l10n.authValidationConfirmPasswordRequired;
      }
      if (trimmed != password) {
        return l10n.authValidationConfirmPasswordMismatch;
      }
      return null;
    };
  }
}
