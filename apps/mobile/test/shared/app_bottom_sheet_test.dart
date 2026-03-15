import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/shared/widgets/app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppBottomSheet', () {
    testWidgets('renders child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppBottomSheet(
              child: const Text('Sheet content'),
            ),
          ),
        ),
      );

      expect(find.text('Sheet content'), findsOneWidget);
    });

    testWidgets('renders title when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppBottomSheet(
              title: 'Bottom Sheet Title',
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Bottom Sheet Title'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('renders sheet handle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppBottomSheet(
              child: const Text('Content'),
            ),
          ),
        ),
      );

      final handleContainer = find.byWidgetPredicate(
        (Widget w) {
          if (w is! Container) return false;
          final decoration = w.decoration;
          return decoration is BoxDecoration &&
              decoration.color == AppColors.divider;
        },
      );
      expect(handleContainer, findsOneWidget);
    });
  });
}
