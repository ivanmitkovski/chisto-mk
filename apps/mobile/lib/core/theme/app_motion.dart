import 'package:flutter/material.dart';

class AppMotion {
  const AppMotion._();

  static const Duration xFast = Duration(milliseconds: 140);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 220);
  static const Duration standard = Duration(milliseconds: 320);
  static const Duration emphasizedDuration = Duration(milliseconds: 420);
  static const Duration slow = Duration(milliseconds: 700);

  // --- Map (cluster expansion, camera) — keep durations aligned across map UI.

  /// Ghost cluster fade-out after a cluster expands ([ClusterGhostMarker]).
  static const Duration mapClusterGhostClear = Duration(milliseconds: 280);

  /// How long pins keep “burst from cluster” entrance choreography.
  static const Duration mapClusterExpansionHold = Duration(milliseconds: 1800);

  /// Default camera fly when fitting bounds or moving to a pin/cluster.
  static const Duration mapCameraFly = Duration(milliseconds: 520);

  /// Camera easing for programmatic map moves (cluster expand, pin select).
  static const Curve mapCameraFlyCurve = Curves.easeOutCubic;

  /// Cluster chip cross-fade when count/membership reflows after zoom/pan.
  static const Duration mapClusterReclusterSwitcher = Duration(milliseconds: 380);

  /// Marker [LatLng] eases toward new cluster geometry (split / merge / pan).
  static const Duration mapMarkerGeographicLerp = Duration(milliseconds: 340);

  /// Easing for geographic marker lerp (map space).
  static const Curve mapMarkerGeographicLerpCurve = Curves.easeOutCubic;

  /// Minimum time to show the reports list skeleton to avoid flash on fast API.
  static const Duration reportsListSkeletonMinHold = Duration(
    milliseconds: 400,
  );

  /// Coalesce rapid realtime events before reloading the reports list.
  static const Duration reportsListRealtimeCoalesce = Duration(
    milliseconds: 450,
  );

  /// Full rotation of the branded loading ring overlay.
  static const Duration loadingOverlayLoop = Duration(milliseconds: 1200);

  /// Checkmark draw phase inside success dialogs.
  static const Duration successCheckReveal = Duration(milliseconds: 500);

  /// Repeating skeleton shimmer: snaps to [staticValue] when reduce motion is on.
  static void syncRepeatingShimmer(
    AnimationController controller,
    BuildContext context, {
    double staticValue = 0.5,
  }) {
    assert(staticValue >= 0 && staticValue <= 1);
    if (!context.mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.stop();
      controller.value = staticValue;
      return;
    }
    if (!controller.isAnimating) {
      controller.repeat();
    }
  }

  /// Loading overlay ring: static pose when reduce motion is on.
  static void syncLoadingRing(
    AnimationController controller,
    BuildContext context, {
    required bool visible,
    double staticValue = 0.25,
  }) {
    assert(staticValue >= 0 && staticValue <= 1);
    if (!context.mounted) return;
    if (!visible) {
      controller.stop();
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.stop();
      controller.value = staticValue;
      return;
    }
    controller.repeat();
  }

  /// One full three-dot typing wave (event chat).
  static const Duration chatTypingCycle = Duration(milliseconds: 1500);

  /// Message bubble fade + horizontal slide-in (event chat).
  static const Duration chatBubbleEntrance = Duration(milliseconds: 400);

  /// Eased phase 0–1 for typing dots each [chatTypingCycle] (calmer than linear).
  static const Curve chatTypingPhaseCurve = Curves.easeInOutCubic;

  /// Entrance curve for chat bubbles (matches iOS-style deceleration).
  static const Curve chatBubbleEntranceCurve = smooth;

  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve smooth = Cubic(0.33, 0.0, 0.2, 1.0);
  static const Curve spring = Curves.easeOutBack;
  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve decelerate = Curves.easeInOutCubic;
  static const Curve sharpDecelerate = Cubic(0.2, 0.0, 0.0, 1.0);

  static SpringDescription get snappySpring =>
      const SpringDescription(mass: 1.0, stiffness: 400.0, damping: 28.0);

  static SpringDescription get bouncySpring =>
      const SpringDescription(mass: 1.0, stiffness: 300.0, damping: 18.0);

  static SpringDescription get gentleSpring =>
      const SpringDescription(mass: 1.0, stiffness: 180.0, damping: 22.0);

  static Duration staggerDelay(int index, {int perItemMs = 35}) =>
      Duration(milliseconds: fast.inMilliseconds + index * perItemMs);

  static Interval staggerInterval(
    int index, {
    int totalItems = 8,
    double overlapFraction = 0.3,
  }) {
    final double itemDuration =
        1.0 / (totalItems * (1.0 - overlapFraction) + overlapFraction);
    final double start = index * itemDuration * (1.0 - overlapFraction);
    final double end = (start + itemDuration).clamp(0.0, 1.0);
    return Interval(start.clamp(0.0, 1.0), end, curve: emphasized);
  }
}
