import 'package:chisto_infrastructure/shared/widgets/atoms/primary_button.dart';
import 'package:feature_auth/src/presentation/screens/forgot_password_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/pump_auth_app.dart';
import '../../shared/widget_test_bootstrap.dart';

Finder _primaryCta(String label) {
  return find.byWidgetPredicate(
    (Widget w) => w is PrimaryButton && w.label == label,
  );
}

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('defaults to phone field without segmented control', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(tester, home: const ForgotPasswordRequestScreen());
    await tester.pumpAndSettle();

    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Email'), findsNothing);
    expect(find.byType(SegmentedButton<bool>), findsNothing);
    expect(_primaryCta('Send reset code'), findsOneWidget);
    expect(
      find.text(
        "Enter your phone number and we'll send you a code to reset your password",
      ),
      findsOneWidget,
    );
  });

  Future<void> tapAlternateMethod(WidgetTester tester) async {
    final Finder link = find.byKey(
      const Key('auth_forgot_password_alternate_method'),
    );
    await tester.ensureVisible(link);
    await tester.tap(link);
  }

  testWidgets('bottom link switches to email reset', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(tester, home: const ForgotPasswordRequestScreen());
    await tester.pumpAndSettle();

    await tapAlternateMethod(tester);
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Phone number'), findsNothing);
    expect(_primaryCta('Send reset link'), findsOneWidget);
    expect(
      find.text(
        "Enter the email on your account and we'll send a reset link if it exists.",
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('auth_forgot_password_alternate_method')),
      findsOneWidget,
    );
  });

  testWidgets('bottom link switches back to phone reset', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(tester, home: const ForgotPasswordRequestScreen());
    await tester.pumpAndSettle();

    await tapAlternateMethod(tester);
    await tester.pumpAndSettle();

    await tapAlternateMethod(tester);
    await tester.pumpAndSettle();

    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Email'), findsNothing);
    expect(_primaryCta('Send reset code'), findsOneWidget);
    expect(
      find.byKey(const Key('auth_forgot_password_alternate_method')),
      findsOneWidget,
    );
  });
}
