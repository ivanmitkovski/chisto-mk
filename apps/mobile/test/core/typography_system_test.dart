import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTypography tokens', () {
    test('cardTitle derives from titleSmall scale', () {
      const TextTheme theme = AppTypography.textTheme;
      final TextStyle style = AppTypography.cardTitle(theme);
      expect(style.fontSize, 16);
      expect(style.fontWeight, FontWeight.w600);
    });

    test('badgeLabel uses micro scale', () {
      final TextStyle style = AppTypography.badgeLabel(AppTypography.textTheme);
      expect(style.fontSize, 11);
      expect(style.fontWeight, FontWeight.w700);
    });

    test('buttonLabel uses labelLarge scale', () {
      final TextStyle style = AppTypography.buttonLabel(
        AppTypography.textTheme,
      );
      expect(style.fontSize, 17);
      expect(style.fontWeight, FontWeight.w600);
    });
  });

  group('AppText', () {
    testWidgets('cardTitle renders with Roboto from theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: AppText.cardTitle('Hello')),
        ),
      );

      final Text text = tester.widget<Text>(find.text('Hello'));
      expect(text.style?.fontFamily, contains('Roboto'));
      expect(text.style?.fontSize, 16);
    });

    testWidgets('respects textScaler at 1.3x without overflow in bounded box', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: Scaffold(
              body: SizedBox(
                width: 200,
                child: AppText.body('Scaled body text'),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Scaled body text'), findsOneWidget);
    });
  });
}
