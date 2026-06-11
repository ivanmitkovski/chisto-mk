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

Finder _primaryCtaElevated(String label) {
  return find.descendant(
    of: _primaryCta(label),
    matching: find.byType(ElevatedButton),
  );
}

ElevatedButton primaryElevatedWidget(WidgetTester tester, String label) {
  return tester.widget<ElevatedButton>(_primaryCtaElevated(label));
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
    expect(_primaryCta('Send reset code'), findsOneWidget);
    expect(
      find.text(
        "Enter the email on your account and we'll send a reset code if it exists.",
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

  testWidgets('Send reset code is always tappable when not loading', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(tester, home: const ForgotPasswordRequestScreen());
    await tester.pumpAndSettle();

    expect(primaryElevatedWidget(tester, 'Send reset code').onPressed, isNotNull);
  });

  testWidgets('invalid phone submit shows inline error', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(tester, home: const ForgotPasswordRequestScreen());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '123');
    await tester.pump();

    await tester.tap(_primaryCtaElevated('Send reset code'));
    await tester.pumpAndSettle();

    expect(find.text('Enter an 8-digit phone number'), findsOneWidget);
  });

  testWidgets('invalid email submit shows inline error', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(tester, home: const ForgotPasswordRequestScreen());
    await tester.pumpAndSettle();

    await tapAlternateMethod(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'not-an-email');
    await tester.pump();

    await tester.tap(_primaryCtaElevated('Send reset code'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email'), findsOneWidget);
  });
}
