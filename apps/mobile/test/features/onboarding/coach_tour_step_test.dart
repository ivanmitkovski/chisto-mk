import 'package:feature_onboarding/src/domain/coach_tour_step.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kCoachTourSteps defines ordered home shell targets', () {
    expect(kCoachTourSteps, hasLength(6));
    expect(kCoachTourSteps.first.target, CoachTourTarget.none);
    expect(kCoachTourSteps.last.target, CoachTourTarget.profileAvatar);
  });

  test('kCoachTourSteps tab indices stay within shell branches', () {
    for (final CoachTourStep step in kCoachTourSteps) {
      expect(step.requiredTabIndex, inInclusiveRange(0, 3));
    }
  });

  test('kCoachTourSteps includes FAB and map spotlight steps', () {
    final List<CoachTourTarget> targets = kCoachTourSteps
        .map((CoachTourStep s) => s.target)
        .toList(growable: false);
    expect(targets, contains(CoachTourTarget.navMap));
    expect(targets, contains(CoachTourTarget.centralFab));
    expect(targets, contains(CoachTourTarget.navEvents));
  });
}
