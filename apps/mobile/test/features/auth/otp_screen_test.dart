import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/otp_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String testPhoneNumber = '+389 71 234 567';

  Widget buildTestApp() {
    return MaterialApp(
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: OtpScreen(phoneNumber: testPhoneNumber),
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

    expect(
      find.text('We just sent a 4‑digit code to $testPhoneNumber'),
      findsOneWidget,
    );
  });

  testWidgets('renders 4 OTP digit boxes', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final otpRow = find.byWidgetPredicate(
      (Widget w) => w is Row && (w as Row).children.length == 4,
    );
    expect(otpRow, findsOneWidget);
  });

  testWidgets('Continue button is disabled when code is incomplete', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final ElevatedButton continueButton = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Continue'),
        matching: find.byType(ElevatedButton),
      ).first,
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

    final resendButton = find.byType(TextButton);
    expect(resendButton, findsOneWidget);
    final button = tester.widget<TextButton>(resendButton);
    expect(button.onPressed, isNotNull);
  });
}
