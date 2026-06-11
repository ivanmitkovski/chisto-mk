import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/forms/form_validators.dart';
import 'package:feature_auth/src/presentation/utils/auth_validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('FormValidators.strongPassword', () {
    test('rejects weak common pattern qwerty123', () {
      expect(FormValidators.strongPassword(l10n, 'qwerty123#'), isNotNull);
    });

    test('accepts mixed password without weak pattern', () {
      expect(FormValidators.strongPassword(l10n, 'MySecure9x'), isNull);
    });

    test('rejects password longer than 72 characters', () {
      expect(
        FormValidators.strongPassword(l10n, 'a1${'x' * 72}'),
        equals(l10n.authValidationPasswordTooLong),
      );
    });
  });

  group('FormValidators.loginPassword', () {
    test('requires non-empty only', () {
      expect(FormValidators.loginPassword(l10n, ''), isNotNull);
      expect(FormValidators.loginPassword(l10n, 'legacy'), isNull);
    });
  });

  group('FormValidators.otpCode', () {
    test('requires six digits', () {
      expect(
        FormValidators.otpCode(l10n, ''),
        equals(l10n.authValidationOtpRequired),
      );
      expect(
        FormValidators.otpCode(l10n, '12345'),
        equals(l10n.authValidationOtpDigits),
      );
      expect(FormValidators.otpCode(l10n, '123456'), isNull);
    });
  });

  group('AuthValidators.otpInlineError', () {
    test('hides required error until submit on empty field', () {
      expect(
        AuthValidators.otpInlineError(
          l10n: l10n,
          code: '',
          submitAttempted: false,
        ),
        isNull,
      );
      expect(
        AuthValidators.otpInlineError(
          l10n: l10n,
          code: '',
          submitAttempted: true,
        ),
        equals(l10n.authValidationOtpRequired),
      );
    });

    test('hides length errors while typing before submit', () {
      expect(
        AuthValidators.otpInlineError(
          l10n: l10n,
          code: '12345',
          submitAttempted: false,
        ),
        isNull,
      );
      expect(
        AuthValidators.otpInlineError(
          l10n: l10n,
          code: '12345',
          submitAttempted: true,
        ),
        equals(l10n.authValidationOtpDigits),
      );
    });
  });

  group('FormValidators.fullName', () {
    test('requires two parts with min length', () {
      expect(FormValidators.fullName(l10n, 'John'), isNotNull);
      expect(
        FormValidators.fullName(l10n, 'J Doe'),
        equals(l10n.authValidationNameTooShort),
      );
      expect(FormValidators.fullName(l10n, 'John Doe'), isNull);
    });
  });

  group('FormValidators.termsAccepted', () {
    test('requires acceptance', () {
      expect(FormValidators.termsAccepted(l10n, false), isNotNull);
      expect(FormValidators.termsAccepted(l10n, true), isNull);
    });
  });
}
