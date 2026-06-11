import 'package:chisto_core/chisto_core.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/forms/field_error_mapping.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('maps REGISTRATION_CONFLICT to email and phone', () {
    const AppError error = AppError(
      code: 'REGISTRATION_CONFLICT',
      message: 'conflict',
    );
    final Map<String, String> mapped = fieldErrorsFromAppError(error, l10n);
    expect(mapped[FormFieldIds.email], l10n.authErrorRegistrationConflict);
    expect(mapped[FormFieldIds.phone], l10n.authErrorRegistrationConflict);
  });

  test('maps VALIDATION_ERROR constraint keys to localized field messages', () {
    final AppError error = AppError.validation(
      message: 'Validation failed',
      details: <Map<String, dynamic>>[
        <String, dynamic>{
          'field': 'email',
          'constraints': <String, String>{'isEmail': 'must be email'},
        },
        <String, dynamic>{
          'field': 'phoneNumber',
          'constraints': <String, String>{'isPhoneNumber': 'invalid'},
        },
      ],
    );
    final Map<String, String> mapped = fieldErrorsFromAppError(error, l10n);
    expect(mapped[FormFieldIds.email], l10n.authValidationEmailInvalid);
    expect(mapped[FormFieldIds.phone], l10n.authValidationPhoneDigits);
  });

  test('maps OTP_INVALID to otp field', () {
    const AppError error = AppError(code: 'OTP_INVALID', message: 'bad code');
    final Map<String, String> mapped = fieldErrorsFromAppError(error, l10n);
    expect(mapped[FormFieldIds.otp], l10n.authErrorOtpInvalid);
  });
}
