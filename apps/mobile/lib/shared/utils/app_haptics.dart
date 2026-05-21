import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Central haptics for Chisto mobile. Prefer these over raw [HapticFeedback].
///
/// **Reduce motion:** Pass [BuildContext] so haptics respect
/// `MediaQuery.disableAnimationsOf` (system accessibility).
///
/// Use sparingly — see `docs/haptics-policy.md`.
class AppHaptics {
  const AppHaptics._();

  static bool _allowed([BuildContext? context]) {
    if (context == null) return true;
    return !MediaQuery.disableAnimationsOf(context);
  }

  /// Tab, segment, or chip selection.
  static void tap([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.selectionClick();
  }

  /// Light acknowledgment (e.g. map long-press hint).
  static void light([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.lightImpact();
  }

  /// Standard emphasis (reserved for rare milestones).
  static void medium([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.mediumImpact();
  }

  /// Completed flow (save, submit, permission granted).
  static void success([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.lightImpact();
  }

  /// Validation, caution, or permission denied.
  static void warning([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.mediumImpact();
  }

  /// Destructive confirm or hard failure.
  static void error([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.heavyImpact();
  }
}
