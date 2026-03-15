import 'package:chisto_mobile/core/app_theme.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
  });
}
