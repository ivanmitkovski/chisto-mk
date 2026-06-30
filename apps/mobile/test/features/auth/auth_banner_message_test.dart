import 'package:chisto_core/chisto_core.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/forms/field_error_mapping.dart';
import 'package:feature_auth/src/presentation/constants/auth_error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('returns null when mapped error targets a displayed field', () {
    final AppError error = AppError.validation(
      message: 'Validation failed',
      details: <Map<String, dynamic>>[
        <String, dynamic>{
          'field': 'password',
          'constraints': <String, String>{'minLength': 'min 8'},
        },
      ],
    );

    expect(
      authBannerMessageForError(
        l10n,
        error,
        displayedFieldIds: <String>{FormFieldIds.password},
      ),
      isNull,
    );
  });

  test('returns generic copy for unmappable VALIDATION_ERROR', () {
    final AppError error = AppError.validation(
      message: 'Validation failed',
      details: <Map<String, dynamic>>[
        <String, dynamic>{
          'field': 'rememberMe',
          'constraints': <String, String>{'whitelistValidation': 'invalid'},
        },
      ],
    );

    expect(
      authBannerMessageForError(
        l10n,
        error,
        displayedFieldIds: <String>{FormFieldIds.otp},
      ),
      l10n.errorUserValidationGeneric,
    );
  });

  test('returns credentials copy for INVALID_CREDENTIALS', () {
    const AppError error = AppError(
      code: 'INVALID_CREDENTIALS',
      message: 'bad credentials',
    );

    expect(
      authBannerMessageForError(
        l10n,
        error,
        displayedFieldIds: <String>{FormFieldIds.password},
      ),
      l10n.authErrorInvalidCredentials,
    );
  });

  test('returns generic copy when mapped field is not displayed', () {
    final AppError error = AppError.validation(
      message: 'Validation failed',
      details: <Map<String, dynamic>>[
        <String, dynamic>{
          'field': 'phoneNumber',
          'constraints': <String, String>{'isPhoneNumber': 'invalid'},
        },
      ],
    );

    expect(
      authBannerMessageForError(
        l10n,
        error,
        displayedFieldIds: <String>{FormFieldIds.otp},
      ),
      l10n.errorUserValidationGeneric,
    );
  });
}
