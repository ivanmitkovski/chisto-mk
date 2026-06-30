import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_localization/core/l10n/app_error_localizations.dart';
import 'package:chisto_localization/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('localizedAppErrorMessage', () {
    late AppLocalizations l10n;

    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('maps known auth and event codes', () {
      expect(
        localizedAppErrorMessage(
          l10n,
          const AppError(code: 'ALREADY_JOINED', message: 'English leak'),
        ),
        l10n.errorAlreadyJoined,
      );
      expect(
        localizedAppErrorMessage(
          l10n,
          const AppError(code: 'OTP_SEND_COOLDOWN', message: 'wait'),
        ),
        l10n.errorOtpSendCooldown,
      );
    });

    test('never returns raw English for unknown codes', () {
      const String english = 'Database connection refused on host db.internal';
      final String resolved = localizedAppErrorMessage(
        l10n,
        const AppError(code: 'SOME_NEW_CODE', message: english),
      );
      expect(resolved, isNot(english));
      expect(resolved, l10n.errorUserUnknown);
    });

    test('generic fallbacks by class', () {
      expect(
        localizedAppErrorMessage(
          l10n,
          const AppError(code: 'NETWORK_ERROR', message: 'socket'),
        ),
        l10n.errorUserNetwork,
      );
      expect(
        localizedAppErrorMessage(
          l10n,
          const AppError(
            code: 'NETWORK_ERROR',
            message: "Failed host lookup: 'api.chisto.mk'",
          ),
        ),
        isNot(contains('Failed host lookup')),
      );
      expect(
        localizedAppErrorMessage(
          l10n,
          const AppError(code: 'TIMEOUT', message: 'slow'),
        ),
        l10n.errorUserTimeout,
      );
    });

    test('detail includes retry-after seconds', () {
      expect(
        localizedAppErrorDetailMessage(
          l10n,
          const AppError(
            code: 'TOO_MANY_REQUESTS',
            message: 'rate',
            details: <String, int>{'retryAfterSeconds': 30},
          ),
        ),
        l10n.errorUserRetryAfterSeconds(30),
      );
    });
  });
}
