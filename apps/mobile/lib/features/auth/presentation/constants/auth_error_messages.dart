import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

/// Maps API [AppError.code] values to localized user-facing copy.
String messageForAuthError(AppLocalizations l10n, AppError e) {
  switch (e.code) {
    case 'INVALID_CREDENTIALS':
      return l10n.authErrorInvalidCredentials;
    case 'ACCOUNT_SUSPENDED':
    case 'ACCOUNT_NOT_ACTIVE':
      return l10n.authErrorAccountSuspended;
    case 'PHONE_NOT_REGISTERED':
      return l10n.authErrorPhoneNotRegistered;
    case 'EMAIL_ALREADY_REGISTERED':
      return l10n.authErrorEmailRegistered;
    case 'PHONE_ALREADY_REGISTERED':
      return l10n.authErrorPhoneRegistered;
    case 'OTP_NOT_FOUND':
      return l10n.authErrorOtpNotFound;
    case 'OTP_EXPIRED':
      return l10n.authErrorOtpExpired;
    case 'OTP_INVALID':
      return l10n.authErrorOtpInvalid;
    case 'OTP_MAX_ATTEMPTS':
      return l10n.authErrorOtpMaxAttempts;
    case 'CURRENT_PASSWORD_INVALID':
      return l10n.authErrorCurrentPasswordInvalid;
    case 'USER_NOT_FOUND':
      return l10n.authErrorUserNotFound;
    case 'TOO_MANY_REQUESTS':
      return l10n.authErrorRateLimited;
    case 'TOO_MANY_ATTEMPTS':
      return l10n.authErrorTooManyAttempts;
    case 'VALIDATION_ERROR':
    case 'BAD_REQUEST':
    case 'UNAUTHORIZED':
    case 'CONFLICT':
      return e.message;
    default:
      return e.message;
  }
}
