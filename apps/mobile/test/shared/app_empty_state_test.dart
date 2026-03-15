import 'package:chisto_mobile/shared/widgets/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppEmptyState', () {
    testWidgets('renders icon and title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'No items yet',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.text('No items yet'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
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

    testWidgets('renders action widget when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'No items',
              action: ElevatedButton(
                onPressed: () {},
                child: const Text('Add'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Add'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('does not render subtitle when null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'No items',
            ),
          ),
        ),
      );

      expect(find.text('No items'), findsOneWidget);
      expect(find.text('Add something to get started'), findsNothing);
    });

    testWidgets('does not render action when null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'No items',
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });
  });
}
