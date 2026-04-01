import 'package:chisto_mobile/features/auth/presentation/constants/auth_error_messages.dart';
import 'package:chisto_mobile/features/auth/presentation/utils/auth_validators.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AuthValidators uses l10n for email and phone', (WidgetTester tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (BuildContext context) {
            l10n = AppLocalizations.of(context)!;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(AuthValidators.email(l10n, ''), isNotNull);
    expect(AuthValidators.email(l10n, 'not-an-email'), isNotNull);
    expect(AuthValidators.email(l10n, 'a@b.co'), isNull);

    expect(AuthValidators.macedonianPhone(l10n, ''), isNotNull);
    expect(AuthValidators.macedonianPhone(l10n, '70123456'), isNull);
  });

  testWidgets('messageForAuthError maps known codes', (WidgetTester tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (BuildContext context) {
            l10n = AppLocalizations.of(context)!;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(
      messageForAuthError(l10n, const AppError(code: 'INVALID_CREDENTIALS', message: 'x')),
      l10n.authErrorInvalidCredentials,
    );
    expect(
      messageForAuthError(l10n, const AppError(code: 'UNKNOWN', message: 'Server said')),
      'Server said',
    );
  });
}
