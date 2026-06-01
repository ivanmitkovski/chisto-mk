import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme', () {
    test('light returns a ThemeData', () {
      final theme = AppTheme.light;

      expect(theme, isA<ThemeData>());
    });

    test('uses correct scaffold background color', () {
      final theme = AppTheme.light;

      expect(theme.scaffoldBackgroundColor, equals(AppColors.appBackground));
    });

    test('uses Material 3', () {
      final theme = AppTheme.light;

      expect(theme.useMaterial3, isTrue);
    });

    test('text theme uses Roboto on all M3 slots', () {
      final TextTheme textTheme = AppTheme.light.textTheme;

      for (final TextStyle? style in <TextStyle?>[
        textTheme.displayLarge,
        textTheme.displayMedium,
        textTheme.displaySmall,
        textTheme.headlineLarge,
        textTheme.headlineMedium,
        textTheme.headlineSmall,
        textTheme.titleLarge,
        textTheme.titleMedium,
        textTheme.titleSmall,
        textTheme.bodyLarge,
        textTheme.bodyMedium,
        textTheme.bodySmall,
        textTheme.labelLarge,
        textTheme.labelMedium,
        textTheme.labelSmall,
      ]) {
        expect(style?.fontFamily, contains('Roboto'), reason: '$style');
      }
    });

    test('component themes inherit Roboto', () {
      final ThemeData theme = AppTheme.light;

      expect(theme.appBarTheme.titleTextStyle?.fontFamily, contains('Roboto'));
      expect(theme.dialogTheme.titleTextStyle?.fontFamily, contains('Roboto'));
      expect(
        theme.filledButtonTheme.style?.textStyle?.resolve(<WidgetState>{}),
        isNotNull,
      );
      expect(
        theme.listTileTheme.titleTextStyle?.fontFamily,
        contains('Roboto'),
      );
    });
  });
}
