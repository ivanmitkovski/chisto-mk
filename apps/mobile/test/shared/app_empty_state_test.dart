import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppEmptyState', () {
    testWidgets('renders rounded-square icon and title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'No items yet',
            ),
          ),
        ),
      );

      expect(find.byType(AppEmptyStateIcon), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.text('No items yet'), findsOneWidget);

      final RenderBox iconBox = tester.renderObject<RenderBox>(
        find.byType(AppEmptyStateIcon),
      );
      expect(iconBox.size.width, AppSpacing.emptyStateIconBox);
      expect(iconBox.size.height, AppSpacing.emptyStateIconBox);
    });

    testWidgets('renders subtitle when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'No items',
              subtitle: 'Add something to get started',
            ),
          ),
        ),
      );

      expect(find.text('No items'), findsOneWidget);
      expect(find.text('Add something to get started'), findsOneWidget);
    });

    testWidgets('renders secondary and primary actions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'No items',
              secondaryAction: AppButton.text(
                label: 'Clear',
                onPressed: () {},
              ),
              action: AppButton.primary(
                label: 'Add',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('does not render subtitle when null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppEmptyState(icon: Icons.inbox_outlined, title: 'No items'),
          ),
        ),
      );

      expect(find.text('No items'), findsOneWidget);
      expect(find.text('Add something to get started'), findsNothing);
    });

    testWidgets('error icon variant uses danger styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.error_outline_rounded,
              iconVariant: AppEmptyStateIconVariant.error,
              title: 'Something went wrong',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
  });

  group('AppEmptyStateIcon', () {
    testWidgets('animates icon changes when iconKey is set', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppEmptyStateIcon(
              icon: Icons.filter_alt_outlined,
              iconKey: 'a',
              animateIconChanges: true,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedSwitcher), findsOneWidget);
    });
  });
}
