import 'package:chisto_mobile/features/onboarding/presentation/coach/coach_tour_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'computeCoachTourCardLayout places card below hole when space allows',
    () {
      const EdgeInsets pad = EdgeInsets.zero;
      const Rect hole = Rect.fromLTWH(40, 200, 56, 56);
      final CoachTourCardLayoutResult r = computeCoachTourCardLayout(
        paddingInsets: pad,
        maxWidth: 400,
        maxHeight: 800,
        estimatedCardHeight: 200,
        margin: 16,
        verticalGap: 8,
        stepWantsHole: true,
        holeMeasurementFailed: false,
        localHole: hole,
        viewInsetBottom: 0,
        textScaleFactor: 1,
      );
      expect(r.placement, CoachTourCardVerticalPlacement.top);
      expect(r.top, hole.bottom + 16);
    },
  );

  test('computeCoachTourCardLayout uses center fill when keyboard is open', () {
    const EdgeInsets pad = EdgeInsets.zero;
    const Rect hole = Rect.fromLTWH(40, 200, 56, 56);
    final CoachTourCardLayoutResult r = computeCoachTourCardLayout(
      paddingInsets: pad,
      maxWidth: 400,
      maxHeight: 800,
      estimatedCardHeight: 200,
      margin: 16,
      verticalGap: 8,
      stepWantsHole: true,
      holeMeasurementFailed: false,
      localHole: hole,
      viewInsetBottom: 120,
      textScaleFactor: 1,
    );
    expect(r.placement, CoachTourCardVerticalPlacement.centerFill);
    expect(r.bottom, 120 + 16);
  });

  test(
    'computeCoachTourCardLayout top fallback when hole measurement failed',
    () {
      const EdgeInsets pad = EdgeInsets.fromLTRB(8, 44, 8, 20);
      final CoachTourCardLayoutResult r = computeCoachTourCardLayout(
        paddingInsets: pad,
        maxWidth: 360,
        maxHeight: 700,
        estimatedCardHeight: 220,
        margin: 16,
        verticalGap: 8,
        stepWantsHole: true,
        holeMeasurementFailed: true,
        localHole: null,
        viewInsetBottom: 0,
        textScaleFactor: 1.4,
      );
      expect(r.placement, CoachTourCardVerticalPlacement.top);
      expect(r.top, pad.top + 32);
    },
  );

  test(
    'computeCoachTourCardLayout uses visualHole for geometry when provided',
    () {
      const EdgeInsets pad = EdgeInsets.zero;
      const Rect measured = Rect.fromLTWH(40, 200, 56, 56);
      const Rect visual = Rect.fromLTWH(40, 230, 56, 56);
      final CoachTourCardLayoutResult r = computeCoachTourCardLayout(
        paddingInsets: pad,
        maxWidth: 400,
        maxHeight: 800,
        estimatedCardHeight: 200,
        margin: 16,
        verticalGap: 8,
        stepWantsHole: true,
        holeMeasurementFailed: false,
        localHole: measured,
        visualHole: visual,
        viewInsetBottom: 0,
        textScaleFactor: 1,
      );
      expect(r.placement, CoachTourCardVerticalPlacement.top);
      expect(r.top, visual.bottom + 16);
    },
  );
}
