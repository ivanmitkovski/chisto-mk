import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/primary_button.dart';
import 'package:feature_auth/src/presentation/screens/sign_in_screen.dart';
import 'package:feature_auth/src/presentation/screens/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/pump_auth_app.dart';
import '../../shared/widget_test_bootstrap.dart';
import 'support/auth_test_helpers.dart';
import 'support/fake_auth_repository.dart';

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

  testWidgets('renders phone and password fields', (WidgetTester tester) async {
    await pumpAuthWidget(
      tester,
      home: const SignInScreen(),
      overrides: _authTestOverrides,
    );
    await tester.pumpAndSettle();

    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Remember me'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('Sign In button is disabled when fields are empty', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(
      tester,
      home: const SignInScreen(),
      overrides: _authTestOverrides,
    );
    await tester.pumpAndSettle();

    final ElevatedButton signInButton = tester.widget<ElevatedButton>(
      _primaryCtaElevated('Sign in'),
    );
    expect(signInButton.onPressed, isNull);
  });

  testWidgets('Sign In button becomes enabled when both fields have content', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(
      tester,
      home: const SignInScreen(),
      overrides: _authTestOverrides,
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '70123456');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.pump();

    final ElevatedButton signInButton = tester.widget<ElevatedButton>(
      _primaryCtaElevated('Sign in'),
    );
    expect(signInButton.onPressed, isNotNull);
  });

  testWidgets(
    'shows validation error text when form is submitted with invalid data',
    (WidgetTester tester) async {
      await pumpAuthWidget(
        tester,
        home: const SignInScreen(),
        overrides: _authTestOverrides,
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '70123456');
      await tester.enterText(find.byType(TextFormField).last, 'short');
      await tester.pump();

      await tester.ensureVisible(_primaryCtaElevated('Sign in'));
      await tester.tap(_primaryCtaElevated('Sign in'));
      await tester.pumpAndSettle();

      expect(
        find.text('Please check your phone number and password.'),
        findsOneWidget,
      );
    },
  );

  testWidgets("Don't have an account? Sign Up link is present", (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(
      tester,
      home: const SignInScreen(),
      overrides: _authTestOverrides,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Sign up', findRichText: true), findsOneWidget);
  });

  testWidgets('tapping Sign Up link navigates to Sign Up screen', (
    WidgetTester tester,
  ) async {
    AppBootstrap.instance.overrideAuthRepositoryForTests(FakeAuthRepository());
    await pumpAppRouter(tester, initialLocation: AppRoutes.signIn);
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Sign up', findRichText: true));
    await tester.pumpAndSettle();

    expect(find.byType(SignUpScreen), findsOneWidget);
  });
}
