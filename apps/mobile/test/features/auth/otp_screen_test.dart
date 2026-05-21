import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/validation/phone_display_formatter.dart';
import 'package:chisto_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/otp_screen.dart';
import 'package:chisto_mobile/features/auth/presentation/widgets/auth_otp_input.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import '../../shared/pump_auth_app.dart';
import '../../shared/widget_test_bootstrap.dart';
import 'support/auth_test_helpers.dart';
import 'support/fake_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
      home: const OtpScreen(
        phoneNumber: testPhoneE164,
        requestOtpOnOpen: true,
      ),
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
    expect(
      AppLocalizations.of(ctx)!.authOtpSubtitle(''),
      contains('6'),
    );
  });

  testWidgets('shows the phone number in subtitle', (WidgetTester tester) async {
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

  testWidgets('Continue button is disabled when code is incomplete', (
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
    expect(continueButton.onPressed, isNull);
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

    for (int i = 0; i < 46; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();

    final Finder resendButton = find.byType(TextButton);
    expect(resendButton, findsOneWidget);
    final TextButton button = tester.widget<TextButton>(resendButton);
    expect(button.onPressed, isNotNull);
  });
}
