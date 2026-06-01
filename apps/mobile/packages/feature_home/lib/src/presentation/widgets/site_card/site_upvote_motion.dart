import 'package:flutter/material.dart';

/// Durations and flags for site upvote micro-interactions (feed card + detail).
///
/// Lives beside [SiteUpvoteAffordance] so feed/detail polish stays cohesive.
/// Aligns with [AppMotion] timing philosophy (HIG / Material motion: short, decisive).
abstract final class SiteUpvoteMotion {
  /// Short overshoot after tap (optimistic UI; not tied to network completion).
  static const Duration popDuration = Duration(milliseconds: 300);

  /// Subtle scale pulse on engagement counter digits when the value changes.
  static const Duration countBumpDuration = Duration(milliseconds: 160);

  /// Visual scale while pointer is down (rest = 1.0).
  static const double iconPressedScale = 0.94;

  /// Peak scale multiplier during [popDuration].
  static const double iconPopOvershoot = 1.07;

  /// Skip playful motion when the system requests reduced motion.
  static bool microAnimationsEnabled(BuildContext context) {
    final MediaQueryData? mq = MediaQuery.maybeOf(context);
    return mq == null || !mq.disableAnimations;
  }
}
