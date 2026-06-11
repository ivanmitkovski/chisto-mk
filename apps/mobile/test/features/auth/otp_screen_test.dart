import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:chisto_infrastructure/core/validation/phone_display_formatter.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_auth/src/domain/models/auth_session_dtos.dart';
import 'package:feature_auth/src/presentation/screens/otp_screen.dart';
import 'package:feature_auth/src/presentation/widgets/auth_otp_input.dart';
import 'package:feature_auth/src/presentation/widgets/auth_otp_resend_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/pump_auth_app.dart';
import '../../shared/widget_test_bootstrap.dart';
import 'support/auth_test_helpers.dart';
import 'support/fake_auth_repository.dart';

void main() {
  /// E.164 as passed from sign-up navigation.
  const String testPhoneE164 = '+38970123456';

  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('requestOtpOnOpen sends SMS on first frame', (
    WidgetTester tester,
  ) async {
    int requestOtpCalls = 0;
    final FakeAuthRepository repo = FakeAuthRepository(
      requestOtpImpl: (String phone) async {
        requestOtpCalls++;
        expect(phone, testPhoneE164);
        return const SendOtpResult(expiresInSeconds: 300);
      },
    );

    await pumpAuthWidget(
      tester,
      home: const OtpScreen(phoneNumber: testPhoneE164, requestOtpOnOpen: true),
      onGenerateRoute: AppRouter.onGenerateRoute,
      overrides: AuthTestOverrides(authRepository: repo).build(),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(requestOtpCalls, 1);
  });

  testWidgets('renders Enter code title', (WidgetTester tester) async {
    await pumpAuthWidget(
      tester,
      home: const OtpScreen(phoneNumber: testPhoneE164),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
    await tester.pumpAndSettle();

    expect(find.text('Enter code'), findsOneWidget);
  });

  testWidgets('subtitle mentions 6-digit code', (WidgetTester tester) async {
    await pumpAuthWidget(
      tester,
      home: const OtpScreen(phoneNumber: testPhoneE164),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
    await tester.pumpAndSettle();

    final BuildContext ctx = tester.element(find.byType(OtpScreen));
    expect(AppLocalizations.of(ctx)!.authOtpSubtitle(''), contains('6'));
  });

  testWidgets('shows the phone number in subtitle', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(
      tester,
      home: const OtpScreen(phoneNumber: testPhoneE164),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
    await tester.pumpAndSettle();

    final String formatted = formatPhoneForDisplay(testPhoneE164);
    final BuildContext ctx = tester.element(find.byType(OtpScreen));
    expect(
      find.text(AppLocalizations.of(ctx)!.authOtpSubtitle(formatted)),
      findsOneWidget,
    );
  });

  testWidgets('renders 6 OTP digit boxes', (WidgetTester tester) async {
    await pumpAuthWidget(
      tester,
      home: const OtpScreen(phoneNumber: testPhoneE164),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuthOtpInput), findsOneWidget);
  });

  testWidgets('Continue is tappable when code is incomplete (validates on tap)', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(
      tester,
      home: const OtpScreen(phoneNumber: testPhoneE164),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
    await tester.pumpAndSettle();

    final ElevatedButton continueButton = tester.widget<ElevatedButton>(
      find
          .ancestor(
            of: find.text('Continue'),
            matching: find.byType(ElevatedButton),
          )
          .first,
    );
    expect(continueButton.onPressed, isNotNull);
  });

  testWidgets('does not show validation error before user submits', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(
      tester,
      home: const OtpScreen(phoneNumber: testPhoneE164, requestOtpOnOpen: true),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Verification code is required'), findsNothing);
  });

  testWidgets('shows validation error after Continue with empty code', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(
      tester,
      home: const OtpScreen(phoneNumber: testPhoneE164),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
    await tester.pumpAndSettle();

    final ElevatedButton continueButton = tester.widget<ElevatedButton>(
      find
          .ancestor(
            of: find.text('Continue'),
            matching: find.byType(ElevatedButton),
          )
          .first,
    );
    continueButton.onPressed?.call();
    await tester.pump();

    expect(find.text('Verification code is required'), findsOneWidget);
  });

  testWidgets('Resend countdown starts at 45 seconds', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(
      tester,
      home: const OtpScreen(phoneNumber: testPhoneE164),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
    await tester.pumpAndSettle();

    expect(find.text('Resend code in 45s'), findsOneWidget);
  });

  testWidgets('unfocus then tap OTP restores focus', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(
      tester,
      home: const OtpScreen(phoneNumber: testPhoneE164),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
    await tester.pumpAndSettle();

    final Finder otpField = find.descendant(
      of: find.byType(AuthOtpInput),
      matching: find.byType(TextField),
    );
    final TextField field = tester.widget<TextField>(otpField);
    final FocusNode focusNode = field.focusNode!;
    expect(focusNode.hasFocus, isTrue);

    focusNode.unfocus();
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);

    await tester.tap(otpField);
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets("Didn't receive code? text appears after countdown", (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(
      tester,
      home: const OtpScreen(phoneNumber: testPhoneE164),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
    await tester.pumpAndSettle();

    expect(find.text('Resend code in 45s'), findsOneWidget);

    for (int i = 0; i < 45; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump();

    expect(find.byType(AuthOtpResendButton), findsOneWidget);
    final InkWell resend = tester.widget<InkWell>(
      find.descendant(
        of: find.byType(AuthOtpResendButton),
        matching: find.byType(InkWell),
      ),
    );
    expect(resend.onTap, isNotNull);
  });
}
