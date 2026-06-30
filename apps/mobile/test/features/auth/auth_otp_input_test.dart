import 'package:design_system/design_system.dart';
import 'package:feature_auth/src/presentation/widgets/auth_otp_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/auth_test_helpers.dart';

void main() {
  Future<void> pumpOtpInput(
    WidgetTester tester, {
    required TextEditingController controller,
    required FocusNode focusNode,
    ValueChanged<String>? onChanged,
  }) async {
    await pumpAuthWidget(
      tester,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: kAuthTestSurfaceSize.width,
            child: AuthOtpInput(
              controller: controller,
              focusNode: focusNode,
              semanticsLabel: 'Verification code',
              onChanged: onChanged ?? (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder otpTextField() {
    return find.descendant(
      of: find.byType(AuthOtpInput),
      matching: find.byType(TextField),
    );
  }

  testWidgets('tap on overlay field requests focus', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController();
    final FocusNode focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await pumpOtpInput(tester, controller: controller, focusNode: focusNode);

    expect(focusNode.hasFocus, isFalse);
    await tester.tap(otpTextField());
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets('unfocus then tap restores focus', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();
    final FocusNode focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await pumpOtpInput(tester, controller: controller, focusNode: focusNode);

    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    focusNode.unfocus();
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);

    await tester.tap(otpTextField());
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets('digit boxes are wrapped in IgnorePointer', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController();
    final FocusNode focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await pumpOtpInput(tester, controller: controller, focusNode: focusNode);

    expect(
      find.descendant(
        of: find.byType(AuthOtpInput),
        matching: find.byWidgetPredicate(
          (Widget widget) => widget is IgnorePointer && widget.ignoring,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('fourth box is active after three digits entered', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController();
    final FocusNode focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await pumpOtpInput(tester, controller: controller, focusNode: focusNode);
    await enterOtpCode(tester, '123');

    final Finder boxes = find.descendant(
      of: find.byType(AuthOtpInput),
      matching: find.byType(AnimatedContainer),
    );
    expect(boxes, findsNWidgets(6));

    final AnimatedContainer fourthBox = tester.widget<AnimatedContainer>(
      boxes.at(3),
    );
    final BoxDecoration decoration = fourthBox.decoration! as BoxDecoration;
    final Border border = decoration.border! as Border;
    expect(border.top.color, AppColors.primary);
  });

  testWidgets('enterOtpCode helper still works', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();
    final FocusNode focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await pumpOtpInput(tester, controller: controller, focusNode: focusNode);
    await enterOtpCode(tester, '123456');

    expect(controller.text, '123456');
  });
}
