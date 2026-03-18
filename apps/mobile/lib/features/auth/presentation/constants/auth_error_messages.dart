import 'package:chisto_mobile/core/errors/app_error.dart';

String messageForAuthError(AppError e) {
  switch (e.code) {
    case 'INVALID_CREDENTIALS':
      return 'Wrong phone number or password.';
    case 'ACCOUNT_SUSPENDED':
      return 'This account is not active.';
    case 'PHONE_NOT_REGISTERED':
      return 'No account found for this phone number.';
    case 'EMAIL_ALREADY_REGISTERED':
      return 'This email is already registered.';
    case 'PHONE_ALREADY_REGISTERED':
      return 'This phone number is already registered.';
    case 'OTP_NOT_FOUND':
      return 'No code was sent. Request a new code.';
    case 'OTP_EXPIRED':
      return 'This code has expired. Request a new code.';
    case 'OTP_INVALID':
      return 'Invalid code. Please try again.';
    case 'OTP_MAX_ATTEMPTS':
      return 'Too many wrong codes. Request a new code.';
    case 'CURRENT_PASSWORD_INVALID':
      return 'Current password is incorrect.';
    case 'TOO_MANY_ATTEMPTS':
      return 'Too many failed attempts. Try again later.';
    case 'VALIDATION_ERROR':
      return e.message;
    case 'BAD_REQUEST':
      return e.message;
    case 'UNAUTHORIZED':
      return e.message;
    case 'CONFLICT':
      return e.message;
    default:
      return e.message;
  }
}
