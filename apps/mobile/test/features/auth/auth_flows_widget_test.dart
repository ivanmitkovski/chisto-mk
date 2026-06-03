import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/navigation/app_go_router.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_back_button.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/primary_button.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/api_error_banner.dart';
import 'package:feature_auth/src/domain/models/auth_session_dtos.dart';
import 'package:feature_auth/src/domain/models/password_reset_target.dart';
import 'package:feature_auth/src/presentation/screens/forgot_password_new_screen.dart';
import 'package:feature_auth/src/presentation/screens/forgot_password_request_screen.dart';
import 'package:feature_auth/src/presentation/screens/forgot_password_success_screen.dart';
import 'package:feature_auth/src/presentation/screens/otp_screen.dart';
import 'package:feature_auth/src/presentation/screens/sign_in_screen.dart';
import 'package:feature_home/src/application/home_shell_controller.dart';
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

  tearDown(() {
    AppBootstrap.instance.authState.setUnauthenticated();
    if (AppBootstrap.instance.isInitialized) {
      readRoot(homeShellControllerProvider.notifier);
      buildAppGoRouter(initialLocation: AppRoutes.signIn);
    }
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
    expect(find.text('Wrong phone number or password.'), findsOneWidget);
  });

  testWidgets('password reset OTP step navigates to new password screen', (
    WidgetTester tester,
  ) async {
    const PasswordResetTarget target = PasswordResetTarget(
      channel: PasswordResetChannel.sms,
      value: '+38970123456',
    );

    AppBootstrap.instance.overrideAuthRepositoryForTests(FakeAuthRepository());
    AppBootstrap.instance.providerContainer.invalidate(authRepositoryProvider);
    await pumpAppRouter(tester, initialLocation: AppRoutes.signIn);
    appGoRouter.push(AppRoutes.forgotPasswordOtp, extra: target);
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
    final FakeAuthRepository repo =
        FakeAuthRepository(
            requestOtpImpl: (String phone) async {
              requestOtpCalls++;
              expect(phone, phoneE164);
              return const SendOtpResult(expiresInSeconds: 300);
            },
          )
          ..signInError = const AppError(
            code: 'PHONE_NOT_VERIFIED',
            message: 'not verified',
          );

    AppBootstrap.instance.overrideAuthRepositoryForTests(repo);
    AppBootstrap.instance.providerContainer.invalidate(authRepositoryProvider);
    await pumpAppRouter(tester, initialLocation: AppRoutes.signIn);
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

  testWidgets('email reset form submits via confirm', (WidgetTester tester) async {
    const PasswordResetTarget target = PasswordResetTarget(
      channel: PasswordResetChannel.email,
      value: 'user@example.com',
    );
    var emailConfirmed = false;
    final FakeAuthRepository repo = FakeAuthRepository(
      confirmPasswordResetByEmailImpl:
          ({
            required String email,
            required String code,
            required String newPassword,
          }) async {
            emailConfirmed = true;
            expect(email, 'user@example.com');
            expect(code, '123456');
            expect(newPassword, 'Newpass123');
          },
    );

    await pumpAuthWidget(
      tester,
      home: const ForgotPasswordNewScreen(
        target: target,
        code: '123456',
      ),
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

  testWidgets('forgot password request back returns to sign in', (
    WidgetTester tester,
  ) async {
    AppBootstrap.instance.overrideAuthRepositoryForTests(FakeAuthRepository());
    await pumpAppRouter(tester, initialLocation: AppRoutes.signIn);
    await tester.pumpAndSettle();

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(SignInScreen)),
    )!;

    await tester.tap(find.text(l10n.authForgotPassword));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordRequestScreen), findsOneWidget);

    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(ForgotPasswordRequestScreen), findsNothing);
  });

  testWidgets('password reset success navigates to sign in', (
    WidgetTester tester,
  ) async {
    await pumpAppRouter(
      tester,
      initialLocation: AppRoutes.forgotPasswordSuccess,
    );
    await tester.pumpAndSettle();

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(ForgotPasswordSuccessScreen)),
    )!;

    await tester.tap(_primaryCtaElevated(l10n.authBackToSignIn));
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(ForgotPasswordSuccessScreen), findsNothing);
  });
}
