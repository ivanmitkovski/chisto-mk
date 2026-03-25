import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:chisto_mobile/shared/testing/widget_test_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  Widget buildTestApp() {
    return MaterialApp(
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const SignUpScreen(),
    );
  }

  testWidgets('renders all four fields (Full Name, Email, Phone, Password)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));
  });

  testWidgets('Sign Up button is disabled when fields are empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final ElevatedButton signUpButton = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Sign Up'),
        matching: find.byType(ElevatedButton),
      ).first,
    );
    expect(signUpButton.onPressed, isNull);
  });

  testWidgets('Sign Up button becomes enabled when all fields are valid', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'John Doe');
    await tester.enterText(textFields.at(1), 'john@chisto.mk');
    await tester.enterText(textFields.at(2), '70123456');
    await tester.enterText(textFields.at(3), 'password123');
    await tester.pump();

    final ElevatedButton signUpButton = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Sign Up'),
        matching: find.byType(ElevatedButton),
      ).first,
    );
    expect(signUpButton.onPressed, isNotNull);
  });

  testWidgets('Sign Up button stays disabled when any field has invalid data', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), '');
    await tester.enterText(textFields.at(1), 'invalid-email');
    await tester.enterText(textFields.at(2), '123');
    await tester.enterText(textFields.at(3), 'short');
    await tester.pump();

    final ElevatedButton signUpButton = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Sign Up'),
        matching: find.byType(ElevatedButton),
      ).first,
    );
    expect(signUpButton.onPressed, isNull);
  });

  testWidgets("Already have an account? Sign In link is present", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Sign Up'));
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (Widget w) =>
            w is RichText &&
            w.text.toPlainText().contains('Already have an account'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('terms and conditions text is displayed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
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
