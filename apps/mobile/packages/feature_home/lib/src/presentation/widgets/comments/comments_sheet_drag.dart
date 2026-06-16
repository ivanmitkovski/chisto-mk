/// Backward-compatible re-exports for comments sheet drag math.
library;

import 'package:design_system/design_system.dart';

export 'package:design_system/design_system.dart'
    show
        AppSheetDragEndAction,
        AppSheetDragEndResult,
        AppSheetSizeConfig,
        appSheetSizeAfterDrag,
        kAppSheetDismissSlop,
        kAppSheetFlingVelocity,
        kAppSheetLegacyDismissVelocity,
        nearestAppSheetSnapTarget,
        nextHigherAppSheetSnapTarget,
        nextLowerAppSheetSnapTarget,
        resolveAppSheetDragEnd,
        sortedAppSheetSnapCandidates;

const double kCommentsSheetFlingVelocity = kAppSheetFlingVelocity;
const double kCommentsSheetLegacyDismissVelocity =
    kAppSheetLegacyDismissVelocity;
const double kCommentsSheetDismissSlop = kAppSheetDismissSlop;

const double kCommentsSheetMinSize = 0.56;
const double kCommentsSheetInitialSize = 0.74;
const double kCommentsSheetMaxSize = 0.95;
const List<double> kCommentsSheetSnapSizes = <double>[0.74, 0.95];

typedef CommentsSheetDragEndAction = AppSheetDragEndAction;
typedef CommentsSheetDragEndResult = AppSheetDragEndResult;

/// Shared size configuration for the comments [DraggableScrollableSheet].
class CommentsSheetSizeConfig {
  const CommentsSheetSizeConfig({
    required this.minSize,
    required this.maxSize,
    this.snapSizes = const <double>[],
  });

  final double minSize;
  final double maxSize;
  final List<double> snapSizes;

  AppSheetSizeConfig toAppConfig({double? initialSize}) {
    return AppSheetSizeConfig(
      minSize: minSize,
      maxSize: maxSize,
      snapSizes: snapSizes,
      initialSize: initialSize,
    );
  }

  static const CommentsSheetSizeConfig standard = CommentsSheetSizeConfig(
    minSize: kCommentsSheetMinSize,
    maxSize: kCommentsSheetMaxSize,
    snapSizes: kCommentsSheetSnapSizes,
  );
}

double sheetSizeAfterDrag({
  required double size,
  required double deltaSize,
  required double minSize,
  required double maxSize,
}) {
  return appSheetSizeAfterDrag(
    size: size,
    deltaSize: deltaSize,
    minSize: minSize,
    maxSize: maxSize,
  );
}

List<double> sortedSheetSnapCandidates({
  required double minSize,
  required double maxSize,
  required List<double> snapSizes,
}) {
  return sortedAppSheetSnapCandidates(
    minSize: minSize,
    maxSize: maxSize,
    snapSizes: snapSizes,
  );
}

double nearestSnapTarget({
  required double size,
  required List<double> candidates,
}) {
  return nearestAppSheetSnapTarget(size: size, candidates: candidates);
}

double? nextLowerSnapTarget({
  required double size,
  required List<double> candidates,
}) {
  return nextLowerAppSheetSnapTarget(size: size, candidates: candidates);
}

double? nextHigherSnapTarget({
  required double size,
  required List<double> candidates,
}) {
  return nextHigherAppSheetSnapTarget(size: size, candidates: candidates);
}

CommentsSheetDragEndResult resolveSheetDragEnd({
  required double size,
  required double? velocity,
  required double minSize,
  required double maxSize,
  required List<double> snapSizes,
  double flingVelocity = kCommentsSheetFlingVelocity,
  double legacyDismissVelocity = kCommentsSheetLegacyDismissVelocity,
  double dismissSlop = kCommentsSheetDismissSlop,
}) {
  final AppSheetDragEndResult result = resolveAppSheetDragEnd(
    size: size,
    velocity: velocity,
    minSize: minSize,
    maxSize: maxSize,
    snapSizes: snapSizes,
    flingVelocity: flingVelocity,
    legacyDismissVelocity: legacyDismissVelocity,
    dismissSlop: dismissSlop,
  );
  switch (result.action) {
    case AppSheetDragEndAction.animateTo:
      return CommentsSheetDragEndResult.animateTo(result.targetSize);
    case AppSheetDragEndAction.dismiss:
      return const CommentsSheetDragEndResult.dismiss();
  }
}
