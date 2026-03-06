import 'package:flutter/services.dart';

class AppHaptics {
  const AppHaptics._();

  static void tap() => HapticFeedback.selectionClick();
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void strong() => HapticFeedback.heavyImpact();
}
