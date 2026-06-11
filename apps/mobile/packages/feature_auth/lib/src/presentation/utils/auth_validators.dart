import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/forms/form_validators.dart';

/// Form validators for auth flows — delegates to [FormValidators].
class AuthValidators {
  AuthValidators._();

  static String? requiredField(
    AppLocalizations l10n,
    String? value,
    String fieldLabel,
  ) => FormValidators.requiredField(l10n, value, fieldLabel);

  static String? email(AppLocalizations l10n, String? value) =>
      FormValidators.email(l10n, value);

  /// Sign-up / reset: strong password rules (mirrors server).
  static String? password(AppLocalizations l10n, String? value) =>
      FormValidators.strongPassword(l10n, value);

  static String? loginPassword(AppLocalizations l10n, String? value) =>
      FormValidators.loginPassword(l10n, value);

  static String? fullName(AppLocalizations l10n, String? value) =>
      FormValidators.fullName(l10n, value);

  static String? macedonianPhone(AppLocalizations l10n, String? value) =>
      FormValidators.macedonianPhone(l10n, value);

  static String? otpCode(AppLocalizations l10n, String? value) =>
      FormValidators.otpCode(l10n, value);

  /// Inline OTP error: only show validation after submit (or server error while editing).
  static String? otpInlineError({
    required AppLocalizations l10n,
    required String code,
    required bool submitAttempted,
    String? serverError,
  }) {
    if (serverError != null && serverError.isNotEmpty) {
      if (submitAttempted || code.isNotEmpty) {
        return serverError;
      }
    }
    if (!submitAttempted) {
      return null;
    }
    return otpCode(l10n, code);
  }

  static String? termsAccepted(AppLocalizations l10n, bool accepted) =>
      FormValidators.termsAccepted(l10n, accepted);

  static String? Function(String?) confirmPassword(
    AppLocalizations l10n,
    String password,
  ) => FormValidators.confirmPassword(l10n, password);
}
