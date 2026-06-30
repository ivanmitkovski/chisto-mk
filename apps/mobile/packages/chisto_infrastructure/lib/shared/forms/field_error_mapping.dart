import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';

/// Client-side field ids used by forms (maps to server DTO property names).
abstract final class FormFieldIds {
  static const String fullName = 'fullName';
  static const String firstName = 'firstName';
  static const String lastName = 'lastName';
  static const String email = 'email';
  static const String phone = 'phone';
  static const String password = 'password';
  static const String confirmPassword = 'confirmPassword';
  static const String currentPassword = 'currentPassword';
  static const String newPassword = 'newPassword';
  static const String otp = 'otp';
  static const String terms = 'terms';
}

/// Maps API validation/conflict errors to per-field inline messages.
Map<String, String> fieldErrorsFromAppError(
  AppError error,
  AppLocalizations l10n,
) {
  if (error.code == 'REGISTRATION_CONFLICT') {
    final String message = l10n.authErrorRegistrationConflict;
    return <String, String>{
      FormFieldIds.email: message,
      FormFieldIds.phone: message,
    };
  }

  final String? otpInline = _otpInlineError(error, l10n);
  if (otpInline != null) {
    return <String, String>{FormFieldIds.otp: otpInline};
  }

  if (error.code == 'EMAIL_ALREADY_REGISTERED') {
    return <String, String>{FormFieldIds.email: l10n.authErrorEmailRegistered};
  }
  if (error.code == 'PHONE_ALREADY_REGISTERED') {
    return <String, String>{FormFieldIds.phone: l10n.authErrorPhoneRegistered};
  }

  if (error.code != 'VALIDATION_ERROR' && error.code != 'BAD_REQUEST') {
    return const <String, String>{};
  }

  final dynamic details = error.details;
  if (details is! List) {
    return const <String, String>{};
  }

  final Map<String, String> mapped = <String, String>{};
  for (final dynamic entry in details) {
    if (entry is! Map) continue;
    final String? field = _readFieldName(entry);
    if (field == null || field.isEmpty) continue;
    final String? clientId = _serverFieldToClientId(field);
    if (clientId == null) continue;
    final String message = _messageForFieldError(entry, l10n, clientId);
    mapped[clientId] = message;
  }
  return mapped;
}

String? _otpInlineError(AppError error, AppLocalizations l10n) {
  switch (error.code) {
    case 'OTP_NOT_FOUND':
      return l10n.authErrorOtpNotFound;
    case 'OTP_EXPIRED':
      return l10n.authErrorOtpExpired;
    case 'OTP_INVALID':
      return l10n.authErrorOtpInvalid;
    case 'OTP_MAX_ATTEMPTS':
      return l10n.authErrorOtpMaxAttempts;
    default:
      return null;
  }
}

String? _readFieldName(Map<dynamic, dynamic> entry) {
  final dynamic raw = entry['field'];
  if (raw is String) return raw;
  return raw?.toString();
}

String _messageForFieldError(
  Map<dynamic, dynamic> entry,
  AppLocalizations l10n,
  String clientFieldId,
) {
  final dynamic constraintsRaw = entry['constraints'];
  if (constraintsRaw is Map) {
    final String? fromConstraints = _messageForConstraintKeys(
      constraintsRaw,
      l10n,
      clientFieldId,
    );
    if (fromConstraints != null) {
      return fromConstraints;
    }
  }
  return l10n.authValidationGenericInvalid;
}

String? _messageForConstraintKeys(
  Map<dynamic, dynamic> constraints,
  AppLocalizations l10n,
  String clientFieldId,
) {
  for (final String key in _constraintPriority) {
    if (!constraints.containsKey(key)) {
      continue;
    }
    final String? message = _messageForConstraintKey(key, l10n, clientFieldId);
    if (message != null) {
      return message;
    }
  }
  return null;
}

const List<String> _constraintPriority = <String>[
  'isNotEmpty',
  'isString',
  'isEmail',
  'isPhoneNumber',
  'minLength',
  'maxLength',
  'matches',
  'isBoolean',
  'isEnum',
  'isInt',
  'isNumber',
  'isUUID',
  'isDateString',
];

String? _messageForConstraintKey(
  String key,
  AppLocalizations l10n,
  String clientFieldId,
) {
  switch (key) {
    case 'isNotEmpty':
    case 'isString':
      return _requiredMessage(l10n, clientFieldId);
    case 'isEmail':
      return clientFieldId == FormFieldIds.email
          ? l10n.authValidationEmailInvalid
          : l10n.authValidationGenericInvalid;
    case 'isPhoneNumber':
      return l10n.authValidationPhoneDigits;
    case 'minLength':
      if (clientFieldId == FormFieldIds.password ||
          clientFieldId == FormFieldIds.newPassword) {
        return l10n.authValidationPasswordMinLength;
      }
      if (clientFieldId == FormFieldIds.fullName) {
        return l10n.authValidationNameTooShort;
      }
      return l10n.authValidationGenericInvalid;
    case 'maxLength':
      if (clientFieldId == FormFieldIds.password ||
          clientFieldId == FormFieldIds.newPassword) {
        return l10n.authValidationPasswordTooLong;
      }
      if (clientFieldId == FormFieldIds.fullName) {
        return l10n.authValidationNameTooLong;
      }
      return l10n.authValidationGenericInvalid;
    case 'matches':
      return l10n.authValidationConfirmPasswordMismatch;
    default:
      return null;
  }
}

String _requiredMessage(AppLocalizations l10n, String clientFieldId) {
  switch (clientFieldId) {
    case FormFieldIds.email:
      return l10n.authValidationEmailRequired;
    case FormFieldIds.phone:
      return l10n.authValidationPhoneRequired;
    case FormFieldIds.password:
    case FormFieldIds.newPassword:
      return l10n.authValidationPasswordRequired;
    case FormFieldIds.confirmPassword:
      return l10n.authValidationConfirmPasswordRequired;
    case FormFieldIds.otp:
      return l10n.authValidationOtpRequired;
    default:
      return l10n.authValidationGenericInvalid;
  }
}

String? _serverFieldToClientId(String serverField) {
  switch (serverField) {
    case 'firstName':
    case 'lastName':
      return FormFieldIds.fullName;
    case 'email':
      return FormFieldIds.email;
    case 'phoneNumber':
      return FormFieldIds.phone;
    case 'password':
      return FormFieldIds.password;
    case 'newPassword':
      return FormFieldIds.newPassword;
    case 'currentPassword':
      return FormFieldIds.currentPassword;
    case 'code':
      return FormFieldIds.otp;
    default:
      return null;
  }
}
