import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/api_error_banner.dart';
import 'package:feature_auth/src/domain/models/password_reset_target.dart';
import 'package:feature_auth/src/presentation/screens/forgot_password_otp_screen.dart';
import 'package:feature_auth/src/presentation/widgets/auth_otp_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/pump_auth_app.dart';
import '../../shared/widget_test_bootstrap.dart';
import 'support/auth_test_helpers.dart';
import 'support/fake_auth_repository.dart';

void main() {
  const PasswordResetTarget target = PasswordResetTarget(
    channel: PasswordResetChannel.sms,
    value: '+38970123456',
  );

  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('renders six OTP boxes via AuthOtpInput', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(
      tester,
      home: const ForgotPasswordOtpScreen(target: target),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuthOtpInput), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('invalid code shows ApiErrorBanner', (WidgetTester tester) async {
    final FakeAuthRepository repo = FakeAuthRepository()
      ..verifyPasswordResetCodeError = const AppError(
        code: 'OTP_INVALID',
        message: 'Invalid',
      );

    await pumpAuthWidget(
      tester,
      home: const ForgotPasswordOtpScreen(target: target),
      overrides: AuthTestOverrides(authRepository: repo).build(),
    );
    await tester.pumpAndSettle();

    await enterOtpCode(tester, '123456');
    await tester.pumpAndSettle();

    expect(find.byType(ApiErrorBanner), findsOneWidget);
  });

  testWidgets('locks after repeated invalid codes', (
    WidgetTester tester,
  ) async {
    final FakeAuthRepository repo = FakeAuthRepository()
      ..verifyPasswordResetCodeError = const AppError(
        code: 'OTP_INVALID',
        message: 'Invalid',
      );

    await pumpAuthWidget(
      tester,
      home: const ForgotPasswordOtpScreen(target: target),
      overrides: AuthTestOverrides(authRepository: repo).build(),
    );
    await tester.pumpAndSettle();

    for (int i = 0; i < 5; i++) {
      await enterOtpCode(tester, '00000$i');
      await tester.pump();
      if (i < 4) {
        await tester.tap(find.text('Continue'));
        await tester.pump();
      }
    }
    await tester.pumpAndSettle();

    expect(
      find.text('Too many wrong codes. Request a new code.'),
      findsOneWidget,
    );
  });

  testWidgets('valid code enables continue and verifies', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(
      tester,
      home: const ForgotPasswordOtpScreen(target: target),
      overrides: AuthTestOverrides(
        authRepository: FakeAuthRepository(),
      ).build(),
    );
    await tester.pumpAndSettle();

    final Finder field = find.descendant(
      of: find.byType(AuthOtpInput),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, '12345');
    await tester.pump();

    expect(find.text('Continue'), findsOneWidget);
  });
}
