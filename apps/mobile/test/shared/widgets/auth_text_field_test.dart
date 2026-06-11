import 'package:chisto_infrastructure/shared/widgets/atoms/auth_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AuthTextField allows multi-line error text', (
    WidgetTester tester,
  ) async {
    const String longError =
        'Password is too weak. Use a mix of letters and numbers and avoid common patterns.';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: AuthTextField(
              label: 'Password',
              controller: TextEditingController(text: 'testpassword1'),
              validator: (_) => longError,
            ),
          ),
        ),
      ),
    );

    final FormState formState = tester.state<FormState>(find.byType(Form));
    formState.validate();
    await tester.pump();

    final InputDecorator decorator = tester.widget<InputDecorator>(
      find.descendant(
        of: find.byType(AuthTextField),
        matching: find.byType(InputDecorator),
      ),
    );

    expect(decorator.decoration.errorMaxLines, 3);
    expect(find.text(longError), findsOneWidget);
  });
}
