import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestApp() {
    return MaterialApp(
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const SignInScreen(),
    );
  }

  testWidgets('renders phone and password fields', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('Sign In button is disabled when fields are empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final ElevatedButton signInButton = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Sign in'),
        matching: find.byType(ElevatedButton),
      ).first,
    );
    expect(signInButton.onPressed, isNull);
  });

  testWidgets('Sign In button becomes enabled when both fields have content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '71234567');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.pump();

    final ElevatedButton signInButton = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Sign in'),
        matching: find.byType(ElevatedButton),
      ).first,
    );
    expect(signInButton.onPressed, isNotNull);
  });

  testWidgets('shows validation error text when form is submitted with invalid data', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '71234567');
    await tester.enterText(find.byType(TextFormField).last, 'short');
    await tester.pump();

    await tester.tap(
      find.ancestor(
        of: find.text('Sign in'),
        matching: find.byType(ElevatedButton),
      ).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Please check your phone number and password'),
      findsOneWidget,
    );
  });

  testWidgets("Don't have an account? Sign Up link is present", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Sign up', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('tapping Sign Up link navigates to Sign Up screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Sign up', findRichText: true));
    await tester.pumpAndSettle();

    expect(find.byType(SignUpScreen), findsOneWidget);
  });
}
