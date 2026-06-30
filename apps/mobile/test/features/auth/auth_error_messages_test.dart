import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/l10n/app_localizations_en.dart';
import 'package:feature_auth/src/presentation/constants/auth_error_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final AppLocalizationsEn l10n = AppLocalizationsEn();

  test('maps password reset email token codes', () {
    expect(
      messageForAuthError(
        l10n,
        const AppError(
          code: 'PASSWORD_RESET_EMAIL_TOKEN_INVALID',
          message: 'x',
        ),
      ),
      l10n.authErrorPasswordResetTokenInvalid,
    );
    expect(
      messageForAuthError(
        l10n,
        const AppError(code: 'PASSWORD_RESET_EMAIL_EXPIRED', message: 'x'),
      ),
      l10n.authErrorPasswordResetTokenInvalid,
    );
  });

  test('maps PHONE_NOT_VERIFIED', () {
    expect(
      messageForAuthError(
        l10n,
        const AppError(code: 'PHONE_NOT_VERIFIED', message: 'x'),
      ),
      l10n.authErrorPhoneNotVerified,
    );
  });
}
