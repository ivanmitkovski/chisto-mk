import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppAvatar', () {
    testWidgets('renders initials from single name',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppAvatar(name: 'Ivan'),
          ),
        ),
      );

      expect(find.text('I'), findsOneWidget);
    });

    testWidgets('renders initials from full name (first + last)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppAvatar(name: 'Ivan Smith'),
          ),
        ),
      );

      expect(find.text('IS'), findsOneWidget);
    });

    testWidgets('handles empty name gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppAvatar(name: ''),
          ),
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('applies correct size', (WidgetTester tester) async {
      const customSize = 64.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppAvatar(name: 'Test', size: customSize),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(AppAvatar));
      expect(size.width, equals(customSize));
      expect(size.height, equals(customSize));
    });
  });
}
