import 'package:flutter/material.dart';

/// Feature gates for heavier coach visuals (vignette, ring).
abstract final class CoachTourVisualPolicy {
  CoachTourVisualPolicy._();

  /// `COACH_LOW_PERF=true` disables soft vignette + hole ring (older devices / profiling).
  static bool get _lowPerf =>
      const bool.fromEnvironment('COACH_LOW_PERF', defaultValue: false);

  static bool useVignetteAndGlow(BuildContext context) {
    if (_lowPerf) {
      return false;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      return false;
    }
    return true;
  }

  /// Confetti on coach completion (off for reduce motion, low perf, or COACH_LOW_PERF).
  static bool useCompletionConfetti(BuildContext context) {
    if (_lowPerf) {
      return false;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      return false;
    }
    return true;
  }
}
