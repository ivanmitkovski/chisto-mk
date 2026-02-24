import 'package:flutter/material.dart';

/// Chisto.mk app theme configuration.
/// Extend with Figma design tokens as you implement.
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      );
}
