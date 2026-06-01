import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_auth/src/presentation/utils/auth_retry_duration.dart';

int? retryAfterSecondsFromAppError(AppError e) {
  final Object? details = e.details;
  if (details is! Map<String, dynamic>) return null;
  final Object? raw = details['retryAfterSeconds'];
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return null;
}

/// Maps API [AppError.code] values to localized user-facing copy.
String messageForAuthError(AppLocalizations l10n, AppError e) {
  switch (e.code) {
    case 'INVALID_CREDENTIALS':
      return l10n.authErrorInvalidCredentials;
    case 'ACCOUNT_SUSPENDED':
    case 'ACCOUNT_NOT_ACTIVE':
      return l10n.authErrorAccountSuspended;
    case 'PHONE_NOT_VERIFIED':
      return l10n.authErrorPhoneNotVerified;
    case 'PHONE_NOT_REGISTERED':
      return l10n.authErrorPhoneNotRegistered;
    case 'PASSWORD_RESET_TOKEN_INVALID':
    case 'PASSWORD_RESET_EMAIL_TOKEN_INVALID':
    case 'PASSWORD_RESET_EMAIL_EXPIRED':
      return l10n.authErrorPasswordResetTokenInvalid;
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
      {
        final int? retry = retryAfterSecondsFromAppError(e);
        if (retry != null && retry > 0) {
          return l10n.authErrorTooManyAttemptsRetryIn(
            formatAuthRetryDuration(l10n, retry),
          );
        }
        return l10n.authErrorRateLimited;
      }
    case 'TOO_MANY_ATTEMPTS':
      {
        final int? retry = retryAfterSecondsFromAppError(e);
        if (retry != null && retry > 0) {
          return l10n.authErrorTooManyAttemptsRetryIn(
            formatAuthRetryDuration(l10n, retry),
          );
        }
        return l10n.authErrorTooManyAttempts;
      }
    case 'VALIDATION_ERROR':
    case 'BAD_REQUEST':
    case 'UNAUTHORIZED':
    case 'CONFLICT':
      return e.message;
    default:
      return e.message;
  }
}
