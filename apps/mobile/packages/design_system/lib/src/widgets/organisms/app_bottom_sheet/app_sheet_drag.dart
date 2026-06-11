/// Pure drag/snap math for resizable modal bottom sheets.
library;

import 'package:flutter/widgets.dart';

/// Strong fling threshold (px/s) for snap-to-next-size behavior.
const double kAppSheetFlingVelocity = 700;

/// Legacy fast-flick dismiss threshold (px/s) near the minimum snap.
const double kAppSheetLegacyDismissVelocity = 200;

/// When within this distance of [minSize], a downward fling dismisses the sheet.
const double kAppSheetDismissSlop = 0.04;

/// Shared size configuration for a resizable [DraggableScrollableSheet].
class AppSheetSizeConfig {
  const AppSheetSizeConfig({
    required this.minSize,
    required this.maxSize,
    this.snapSizes = const <double>[],
    this.initialSize,
  });

  final double minSize;
  final double maxSize;
  final List<double> snapSizes;
  final double? initialSize;

  double get resolvedInitialSize => initialSize ?? minSize;
}

/// Layout slot height for a resizable sheet below the notch and above the keyboard.
double appSheetViewportSlotHeight({
  required double screenHeight,
  required double topInset,
  required double keyboardInset,
}) {
  return (screenHeight - topInset - keyboardInset).clamp(0.0, screenHeight);
}

/// Bottom IME inset for overlay-model resizable sheets.
///
/// Reads from the platform [View] so callers still see the keyboard after
/// [MediaQuery.removeViewInsets] strips bottom insets from layout descendants.
double appSheetOverlayKeyboardInset(BuildContext context) {
  return MediaQueryData.fromView(View.of(context)).viewInsets.bottom;
}

/// Top inset (notch / Dynamic Island) for modal sheet hosts.
///
/// Reads from the platform [View] because modal bottom-sheet routes strip top
/// padding from descendant [MediaQuery]s; this keeps full-height sheets below
/// the status bar exactly like the resizable comments sheet host.
double appSheetViewportTopInset(BuildContext context) {
  return MediaQueryData.fromView(View.of(context)).viewPadding.top;
}

/// Maps a legacy full-screen detent fraction into the padded viewport slot.
double appSheetScreenFractionToSlot({
  required double screenFraction,
  required double screenHeight,
  required double slotHeight,
}) {
  if (slotHeight <= 0) {
    return screenFraction.clamp(0.0, 1.0);
  }
  return ((screenFraction * screenHeight) / slotHeight).clamp(0.0, 1.0);
}

/// Converts base detents into slot-relative fractions for [AppBottomSheet.showResizable].
///
/// Uses [MediaQueryData.fromView] so notch insets stay correct inside modal routes
/// (which strip top padding via [MediaQuery.removePadding]).
///
/// Keyboard lift is handled separately via bottom padding on the sheet host — do
/// not fold [MediaQueryData.viewInsets] into detent math or the sheet over-shrinks.
AppSheetSizeConfig appSheetSizeConfigForViewport(
  AppSheetSizeConfig base,
  MediaQueryData viewData,
) {
  final double screenHeight = viewData.size.height;
  if (screenHeight <= 0) {
    return base;
  }

  final double topInset = viewData.viewPadding.top;
  final double slotHeight = appSheetViewportSlotHeight(
    screenHeight: screenHeight,
    topInset: topInset,
    keyboardInset: 0,
  );
  if (slotHeight <= 0) {
    return base;
  }

  double toSlot(double screenFraction) => appSheetScreenFractionToSlot(
    screenFraction: screenFraction,
    screenHeight: screenHeight,
    slotHeight: slotHeight,
  );

  const double maxSlot = 1;
  final double minSlot = toSlot(base.minSize).clamp(0.0, maxSlot);
  final List<double> cappedSnaps = base.snapSizes
      .map(toSlot)
      .where((double size) => size <= maxSlot + 0.001)
      .toList(growable: false);
  final double cappedInitial = toSlot(
    base.initialSize ?? base.minSize,
  ).clamp(minSlot, maxSlot);

  return AppSheetSizeConfig(
    minSize: minSlot,
    maxSize: maxSlot,
    snapSizes: cappedSnaps,
    initialSize: cappedInitial,
  );
}

enum AppSheetDragEndAction { animateTo, dismiss }

class AppSheetDragEndResult {
  const AppSheetDragEndResult.animateTo(this.targetSize)
    : action = AppSheetDragEndAction.animateTo;

  const AppSheetDragEndResult.dismiss()
    : action = AppSheetDragEndAction.dismiss,
      targetSize = null;

  final AppSheetDragEndAction action;
  final double? targetSize;
}

/// Returns a clamped sheet fraction after a vertical drag delta.
double appSheetSizeAfterDrag({
  required double size,
  required double deltaSize,
  required double minSize,
  required double maxSize,
}) {
  return (size - deltaSize).clamp(minSize, maxSize);
}

List<double> sortedAppSheetSnapCandidates({
  required double minSize,
  required double maxSize,
  required List<double> snapSizes,
}) {
  final Set<double> candidates = <double>{minSize, maxSize, ...snapSizes};
  final List<double> sorted = candidates.toList()..sort();
  return sorted;
}

double nearestAppSheetSnapTarget({
  required double size,
  required List<double> candidates,
}) {
  double nearest = candidates.first;
  double bestDistance = (size - nearest).abs();
  for (final double candidate in candidates.skip(1)) {
    final double distance = (size - candidate).abs();
    if (distance < bestDistance) {
      nearest = candidate;
      bestDistance = distance;
    }
  }
  return nearest;
}

double? nextLowerAppSheetSnapTarget({
  required double size,
  required List<double> candidates,
}) {
  double? result;
  for (final double candidate in candidates) {
    if (candidate >= size - 0.001) {
      continue;
    }
    if (result == null || candidate > result) {
      result = candidate;
    }
  }
  return result;
}

double? nextHigherAppSheetSnapTarget({
  required double size,
  required List<double> candidates,
}) {
  double? result;
  for (final double candidate in candidates) {
    if (candidate <= size + 0.001) {
      continue;
    }
    if (result == null || candidate < result) {
      result = candidate;
    }
  }
  return result;
}

AppSheetDragEndResult resolveAppSheetDragEnd({
  required double size,
  required double? velocity,
  required double minSize,
  required double maxSize,
  required List<double> snapSizes,
  double flingVelocity = kAppSheetFlingVelocity,
  double legacyDismissVelocity = kAppSheetLegacyDismissVelocity,
  double dismissSlop = kAppSheetDismissSlop,
}) {
  final List<double> candidates = sortedAppSheetSnapCandidates(
    minSize: minSize,
    maxSize: maxSize,
    snapSizes: snapSizes,
  );

  final double? v = velocity;
  if (v != null && v > legacyDismissVelocity && size <= minSize + dismissSlop) {
    return const AppSheetDragEndResult.dismiss();
  }

  if (v != null && v > flingVelocity) {
    if (size <= minSize + dismissSlop) {
      return const AppSheetDragEndResult.dismiss();
    }
    final double? lower = nextLowerAppSheetSnapTarget(
      size: size,
      candidates: candidates,
    );
    if (lower != null) {
      return AppSheetDragEndResult.animateTo(lower);
    }
    return const AppSheetDragEndResult.dismiss();
  }

  if (v != null && v < -flingVelocity) {
    final double? higher = nextHigherAppSheetSnapTarget(
      size: size,
      candidates: candidates,
    );
    if (higher != null) {
      return AppSheetDragEndResult.animateTo(higher);
    }
    return AppSheetDragEndResult.animateTo(maxSize);
  }

  return AppSheetDragEndResult.animateTo(
    nearestAppSheetSnapTarget(size: size, candidates: candidates),
  );
}
