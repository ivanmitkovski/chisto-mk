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

  testWidgets('form body does not scroll when content fits', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAuthWidget(
      tester,
      home: const SignInScreen(),
      overrides: _authTestOverrides,
    );
    await tester.pumpAndSettle();

    final ScrollableState scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(SignInScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(scrollable.position.maxScrollExtent, 0);

    final double pixelsBefore = scrollable.position.pixels;
    await tester.drag(
      find
          .descendant(
            of: find.byType(SignInScreen),
            matching: find.byType(Scrollable),
          )
          .first,
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, pixelsBefore);
  });

  testWidgets('Sign In button is always tappable when not loading', (
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
    expect(signInButton.onPressed, isNotNull);
  });

  testWidgets('Sign In accepts legacy short password on login', (
    WidgetTester tester,
  ) async {
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

    expect(find.text('Password must be at least 8 characters'), findsNothing);
  });

  testWidgets('shows inline validation when phone is invalid on submit', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(
      tester,
      home: const SignInScreen(),
      overrides: _authTestOverrides,
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '123');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.pump();

    await tester.ensureVisible(_primaryCtaElevated('Sign in'));
    await tester.tap(_primaryCtaElevated('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Enter an 8-digit phone number'), findsOneWidget);
  });

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
