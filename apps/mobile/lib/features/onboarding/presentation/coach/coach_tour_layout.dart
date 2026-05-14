import 'dart:math' as math;

import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Vertical placement for the coach tooltip card (pure layout; easy to unit test).
enum CoachTourCardVerticalPlacement { top, bottom, centerFill }

@immutable
class CoachTourCardLayoutResult {
  const CoachTourCardLayoutResult({
    required this.placement,
    required this.top,
    required this.bottom,
    required this.sidePadding,
    required this.maxCardWidth,
  });

  final CoachTourCardVerticalPlacement placement;
  final double? top;
  final double? bottom;
  final double sidePadding;
  final double maxCardWidth;
}

/// Computes tooltip card position from safe area, hole, and viewport size.
///
/// [localHole] is the measured target (branching: top vs bottom vs keyboard).
/// [visualHole] is optional; when set (e.g. morphed spotlight), top/bottom
/// offsets follow it so the card moves with the cutout instead of snapping.
CoachTourCardLayoutResult computeCoachTourCardLayout({
  required EdgeInsets paddingInsets,
  required double maxWidth,
  required double maxHeight,
  required double estimatedCardHeight,
  required double margin,
  required double verticalGap,
  required bool stepWantsHole,
  required bool holeMeasurementFailed,
  required Rect? localHole,
  Rect? visualHole,
  required double viewInsetBottom,
  required double textScaleFactor,
}) {
  final double scale = math.max(1.0, textScaleFactor);
  final double scaledEstimate = estimatedCardHeight * math.min(scale, 1.35);
  final double sidePad = margin;
  const double cardMaxW = 400;
  final double maxCard = cardMaxW.clamp(0.0, maxWidth - 2 * sidePad);

  final double kb = viewInsetBottom;
  final double usableBottom = maxHeight - paddingInsets.bottom - kb;

  if (kb > 56) {
    return CoachTourCardLayoutResult(
      placement: CoachTourCardVerticalPlacement.centerFill,
      top: paddingInsets.top + margin,
      bottom: paddingInsets.bottom + kb + margin,
      sidePadding: sidePad,
      maxCardWidth: maxCard,
    );
  }

  if (!stepWantsHole ||
      localHole == null ||
      localHole.isEmpty ||
      holeMeasurementFailed) {
    final double top = paddingInsets.top + margin * 2;
    return CoachTourCardLayoutResult(
      placement: CoachTourCardVerticalPlacement.top,
      top: top,
      bottom: null,
      sidePadding: sidePad,
      maxCardWidth: maxCard,
    );
  }

  final Rect g = visualHole ?? localHole;

  final double spaceBelow = usableBottom - localHole.bottom - margin;
  if (spaceBelow >= scaledEstimate + verticalGap) {
    return CoachTourCardLayoutResult(
      placement: CoachTourCardVerticalPlacement.top,
      top: g.bottom + AppSpacing.md,
      bottom: null,
      sidePadding: sidePad,
      maxCardWidth: maxCard,
    );
  }

  final double bottomFromTop = maxHeight - g.top + AppSpacing.md;
  return CoachTourCardLayoutResult(
    placement: CoachTourCardVerticalPlacement.bottom,
    top: null,
    bottom: bottomFromTop.clamp(margin, maxHeight - paddingInsets.top),
    sidePadding: sidePad,
    maxCardWidth: maxCard,
  );
}
