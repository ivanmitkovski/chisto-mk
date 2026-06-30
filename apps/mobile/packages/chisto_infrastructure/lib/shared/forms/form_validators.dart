import 'package:chisto_core/chisto_core.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';

/// Localized form validators shared across auth, profile, events, and reports.
class FormValidators {
  FormValidators._();

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

  /// Sign-in password: non-empty only (legacy passwords may not meet sign-up rules).
  static String? loginPassword(AppLocalizations l10n, String? value) {
    if (value == null || value.trim().isEmpty) {
      return l10n.authValidationPasswordRequired;
    }
    return null;
  }

  /// Base password rules (length, letter, number).
  static String? password(AppLocalizations l10n, String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return l10n.authValidationPasswordRequired;
    }
    if (trimmed.length < 8) {
      return l10n.authValidationPasswordMinLength;
    }
    if (trimmed.length > 72) {
      return l10n.authValidationPasswordTooLong;
    }
    if (!RegExp(r'\d').hasMatch(trimmed)) {
      return l10n.authValidationPasswordNeedNumber;
    }
    if (!RegExp('[A-Za-z]').hasMatch(trimmed)) {
      return l10n.authValidationPasswordNeedLetter;
    }
    return null;
  }

  /// Sign-up / reset password: base rules + weak-pattern check (mirrors server).
  static String? strongPassword(AppLocalizations l10n, String? value) {
    final String? base = password(l10n, value);
    if (base != null) return base;
    final String trimmed = value!.trim();
    if (computePasswordStrength(trimmed) == PasswordStrength.weak) {
      return l10n.authValidationPasswordWeak;
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
    for (final String part in parts) {
      if (part.length < 2) {
        return l10n.authValidationNameTooShort;
      }
      if (part.length > 60) {
        return l10n.authValidationNameTooLong;
      }
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

  static String? otpCode(AppLocalizations l10n, String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return l10n.authValidationOtpRequired;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) {
      return l10n.authValidationOtpDigits;
    }
    return null;
  }

  static String? termsAccepted(AppLocalizations l10n, bool accepted) {
    if (!accepted) {
      return l10n.authValidationTermsRequired;
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
