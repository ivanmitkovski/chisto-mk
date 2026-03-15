import 'package:chisto_mobile/shared/widgets/app_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSectionHeader', () {
    testWidgets('renders title text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSectionHeader(title: 'Section Title'),
          ),
        ),
      );

      expect(find.text('Section Title'), findsOneWidget);
    });

    testWidgets('renders trailing widget when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSectionHeader(
              title: 'Section Title',
              trailing: const Text('See all'),
            ),
          ),
        ),
      );

      expect(find.text('Section Title'), findsOneWidget);
      expect(find.text('See all'), findsOneWidget);
    });

    testWidgets('does not render trailing when null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSectionHeader(
              title: 'Section Title',
              trailing: null,
            ),
          ),
        ),
      );

      expect(find.text('Section Title'), findsOneWidget);
      expect(find.text('See all'), findsNothing);
    });
  });
}
