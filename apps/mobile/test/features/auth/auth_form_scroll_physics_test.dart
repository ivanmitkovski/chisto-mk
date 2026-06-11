import 'package:feature_auth/src/presentation/widgets/auth_form_scroll_physics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses platform physics when keyboard is hidden', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            final ScrollPhysics physics = AuthFormScrollPhysics.resolve(
              context,
            );
            expect(physics, isA<ScrollPhysics>());
            expect(physics, isNot(isA<AlwaysScrollableScrollPhysics>()));
            return const SizedBox();
          },
        ),
      ),
    );
  });

  testWidgets('allows scroll when keyboard is visible', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 320)),
          child: Builder(
            builder: (BuildContext context) {
              final ScrollPhysics physics = AuthFormScrollPhysics.resolve(
                context,
              );
              expect(physics, isA<AlwaysScrollableScrollPhysics>());
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  });
}
