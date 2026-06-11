import 'package:chisto_infrastructure/shared/widgets/atoms/primary_button.dart';
import 'package:feature_auth/src/presentation/screens/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/pump_auth_app.dart';
import '../../shared/widget_test_bootstrap.dart';
import 'support/auth_test_helpers.dart';

final List<Override> _authTestOverrides = AuthTestOverrides().build();

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

  testWidgets('renders all four fields (Full name, Email, Phone, Password)', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(
      tester,
      home: const SignUpScreen(),
      overrides: _authTestOverrides,
    );
    await tester.pumpAndSettle();

    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));
  });

  testWidgets('Sign up button is always tappable when not loading', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(
      tester,
      home: const SignUpScreen(),
      overrides: _authTestOverrides,
    );
    await tester.pumpAndSettle();

    final ElevatedButton signUpButton = tester.widget<ElevatedButton>(
      _primaryCtaElevated('Sign up'),
    );
    expect(signUpButton.onPressed, isNotNull);
  });

  testWidgets('empty submit reveals inline validation errors', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(
      tester,
      home: const SignUpScreen(),
      overrides: _authTestOverrides,
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(_primaryCtaElevated('Sign up'));
    await tester.tap(_primaryCtaElevated('Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Full name is required'), findsOneWidget);
    expect(find.text('You must accept the terms and conditions'), findsOneWidget);
  });

  testWidgets('invalid submit reveals inline field errors', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(
      tester,
      home: const SignUpScreen(),
      overrides: _authTestOverrides,
    );
    await tester.pumpAndSettle();

    final Finder textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), '');
    await tester.enterText(textFields.at(1), 'invalid-email');
    await tester.enterText(textFields.at(2), '123');
    await tester.enterText(textFields.at(3), 'short');
    await tester.pump();

    await tester.ensureVisible(_primaryCtaElevated('Sign up'));
    await tester.tap(_primaryCtaElevated('Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Enter an 8-digit phone number'), findsOneWidget);
    expect(
      find.text('Password must be at least 8 characters'),
      findsOneWidget,
    );
  });

  testWidgets('Already have an account? Sign in link is present', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(
      tester,
      home: const SignUpScreen(),
      overrides: _authTestOverrides,
    );
    await tester.pumpAndSettle();

    final Finder signInPrompt = find.byWidgetPredicate(
      (Widget w) =>
          w is RichText &&
          w.text.toPlainText().contains('Already have an account'),
    );
    await tester.ensureVisible(signInPrompt);
    await tester.pumpAndSettle();

    expect(signInPrompt, findsOneWidget);
  });

  testWidgets('terms and conditions text is displayed', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(
      tester,
      home: const SignUpScreen(),
      overrides: _authTestOverrides,
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (Widget w) =>
            w is RichText &&
            w.text.toPlainText().contains('terms and conditions'),
      ),
      findsOneWidget,
    );
  });
}
