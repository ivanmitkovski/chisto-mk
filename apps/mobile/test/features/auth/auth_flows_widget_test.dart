import 'package:chisto_mobile/core/deep_links/deep_link_router.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/forgot_password_new_screen.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/forgot_password_otp_screen.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/otp_screen.dart';
import 'package:chisto_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/molecules/api_error_banner.dart';
import 'package:chisto_mobile/shared/widgets/atoms/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/pump_auth_app.dart';
import '../../shared/widget_test_bootstrap.dart';
import 'support/auth_test_helpers.dart';
import 'support/fake_auth_repository.dart';

Finder _primaryCta(String label) {
  return find.byWidgetPredicate(
    (Widget w) => w is PrimaryButton && w.label == label,
  );
}

Finder _primaryCtaElevated(String label) {
  return find.descendant(
    of: _primaryCta(label),
    matching: find.byType(ElevatedButton),
  );
}

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('sign in shows ApiErrorBanner on invalid credentials', (
    WidgetTester tester,
  ) async {
    final FakeAuthRepository repo = FakeAuthRepository()
      ..signInError = const AppError(code: 'INVALID_CREDENTIALS', message: 'x');

    await pumpAuthWidget(
      tester,
      home: const SignInScreen(),
      overrides: AuthTestOverrides(authRepository: repo).build(),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '70123456');
    await tester.enterText(find.byType(TextFormField).last, 'wrongpass1');
    await tester.pump();

    await tester.ensureVisible(_primaryCtaElevated('Sign in'));
    await tester.tap(_primaryCtaElevated('Sign in'));
    await tester.pumpAndSettle();

    expect(find.byType(ApiErrorBanner), findsOneWidget);
    expect(
      find.text('Wrong phone number or password.'),
      findsOneWidget,
    );
  });

  testWidgets('password reset OTP step navigates to new password screen', (
    WidgetTester tester,
  ) async {
    const String phone = '+38970123456';

    await pumpAuthWidget(
      tester,
      home: const ForgotPasswordOtpScreen(phoneNumberE164: phone),
      onGenerateRoute: AppRouter.onGenerateRoute,
      overrides: AuthTestOverrides(authRepository: FakeAuthRepository()).build(),
    );
    await tester.pumpAndSettle();

    await enterOtpCode(tester, '123456');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordNewScreen), findsOneWidget);
  });

  testWidgets('sign in shows verify dialog on PHONE_NOT_VERIFIED', (
    WidgetTester tester,
  ) async {
    const String phoneE164 = '+38970123456';
    int requestOtpCalls = 0;
    final FakeAuthRepository repo = FakeAuthRepository(
      requestOtpImpl: (String phone) async {
        requestOtpCalls++;
        expect(phone, phoneE164);
        return const SendOtpResult(expiresInSeconds: 300);
      },
    )..signInError = const AppError(
        code: 'PHONE_NOT_VERIFIED',
        message: 'not verified',
      );

    await pumpAuthWidget(
      tester,
      home: const SignInScreen(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      overrides: AuthTestOverrides(authRepository: repo).build(),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '70123456');
    await tester.enterText(find.byType(TextFormField).last, 'Password1');
    await tester.pump();

    await tester.ensureVisible(_primaryCtaElevated('Sign in'));
    await tester.tap(_primaryCtaElevated('Sign in'));
    await tester.pumpAndSettle();

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(SignInScreen)),
    )!;

    expect(find.byType(ApiErrorBanner), findsNothing);
    expect(find.text(l10n.authPhoneNotVerified), findsOneWidget);

    await tester.tap(find.text(l10n.authVerifyPhoneCta));
    await tester.pumpAndSettle();

    expect(find.byType(OtpScreen), findsOneWidget);
    expect(requestOtpCalls, 1);
  });

  testWidgets('email reset deep link opens ForgotPasswordNewScreen', (
    WidgetTester tester,
  ) async {
    const String token = 'email-reset-token-test';

    await pumpAuthWidget(
      tester,
      home: const SignInScreen(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      overrides: AuthTestOverrides(authRepository: FakeAuthRepository()).build(),
    );
    await tester.pumpAndSettle();

    final NavigatorState nav = Navigator.of(
      tester.element(find.byType(SignInScreen)),
    );
    DeepLinkRouter.handleUri(
      nav,
      Uri.parse('https://chisto.mk/reset-password?token=$token'),
      isAuthenticated: false,
    );
    await tester.pumpAndSettle();

    final ForgotPasswordNewScreen screen = tester.widget<ForgotPasswordNewScreen>(
      find.byType(ForgotPasswordNewScreen),
    );
    expect(screen.emailResetToken, token);
  });

  testWidgets('email reset form submits via confirmByEmail', (
    WidgetTester tester,
  ) async {
    const String token = 'reset-tok';
    var emailConfirmed = false;
    final FakeAuthRepository repo = FakeAuthRepository(
      confirmPasswordResetByEmailImpl: ({
        required String token,
        required String newPassword,
      }) async {
        emailConfirmed = true;
        expect(token, 'reset-tok');
        expect(newPassword, 'Newpass123');
      },
    );

    await pumpAuthWidget(
      tester,
      home: ForgotPasswordNewScreen(emailResetToken: token),
      onGenerateRoute: AppRouter.onGenerateRoute,
      overrides: AuthTestOverrides(authRepository: repo).build(),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Newpass123');
    await tester.enterText(find.byType(TextFormField).last, 'Newpass123');
    await tester.pump();

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(ForgotPasswordNewScreen)),
    )!;

    await tester.ensureVisible(_primaryCtaElevated(l10n.authResetPasswordCta));
    await tester.tap(_primaryCtaElevated(l10n.authResetPasswordCta));
    await tester.pumpAndSettle();

    expect(emailConfirmed, isTrue);
  });
}
