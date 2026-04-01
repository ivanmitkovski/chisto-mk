import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/validation/phone_display_formatter.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/otp_screen.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/testing/widget_test_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// E.164 as passed from sign-up navigation.
  const String testPhoneE164 = '+38970123456';

  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  Widget buildTestApp() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const OtpScreen(phoneNumber: testPhoneE164),
    );
  }

  testWidgets('renders Enter code title', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Enter code'), findsOneWidget);
  });

  testWidgets('shows the phone number in subtitle', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final String formatted = formatPhoneForDisplay(testPhoneE164);
    final BuildContext ctx = tester.element(find.byType(OtpScreen));
    expect(
      find.text(AppLocalizations.of(ctx)!.authOtpSubtitle(formatted)),
      findsOneWidget,
    );
  });

  testWidgets('renders 4 OTP digit boxes', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final Finder otpRow = find.byWidgetPredicate(
      (Widget w) => w is Row && w.children.length == 4,
    );
    expect(otpRow, findsOneWidget);
  });

  testWidgets('Continue button is disabled when code is incomplete', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
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
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Resend code in 45s'), findsOneWidget);
  });

  testWidgets("Didn't receive code? text appears after countdown", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
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
