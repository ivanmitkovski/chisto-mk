import 'package:flutter/material.dart';

class AppMotion {
  const AppMotion._();

  // ── Durations ──────────────────────────────────────────────
  static const Duration xFast = Duration(milliseconds: 140);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 220);
  static const Duration standard = Duration(milliseconds: 320);
  static const Duration emphasizedDuration = Duration(milliseconds: 420);
  static const Duration slow = Duration(milliseconds: 700);

  // ── Curves ─────────────────────────────────────────────────
  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve spring = Curves.easeOutBack;
  static const Curve standardCurve = Curves.easeOut;
  static const Curve decelerate = Curves.easeInOut;
  static const Curve sharpDecelerate = Cubic(0.2, 0.0, 0.0, 1.0);

  // ── Spring simulations ─────────────────────────────────────
  static SpringDescription get snappySpring => const SpringDescription(
        mass: 1.0,
        stiffness: 400.0,
        damping: 28.0,
      );

  static SpringDescription get bouncySpring => const SpringDescription(
        mass: 1.0,
        stiffness: 300.0,
        damping: 18.0,
      );

  static SpringDescription get gentleSpring => const SpringDescription(
        mass: 1.0,
        stiffness: 180.0,
        damping: 22.0,
      );

  // ── Stagger helpers ────────────────────────────────────────

  static Duration staggerDelay(int index, {int perItemMs = 35}) =>
      Duration(milliseconds: fast.inMilliseconds + index * perItemMs);

  static Interval staggerInterval(
    int index, {
    int totalItems = 8,
    double overlapFraction = 0.3,
  }) {
    final double itemDuration = 1.0 / (totalItems * (1.0 - overlapFraction) + overlapFraction);
    final double start = index * itemDuration * (1.0 - overlapFraction);
    final double end = (start + itemDuration).clamp(0.0, 1.0);
    return Interval(start.clamp(0.0, 1.0), end, curve: emphasized);
  }
}
