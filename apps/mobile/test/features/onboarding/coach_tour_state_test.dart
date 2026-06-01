import 'package:feature_onboarding/src/application/coach_tour_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CoachTourState defaults are hidden and idle', () {
    const CoachTourState state = CoachTourState();

    expect(state.isVisible, isFalse);
    expect(state.stepIndex, 0);
    expect(state.persistBusy, isFalse);
    expect(state.celebratingCompletion, isFalse);
    expect(state.isCelebratingCompletion, isFalse);
  });

  test('CoachTourState copyWith replaces provided fields only', () {
    const CoachTourState initial = CoachTourState(
      isVisible: true,
      stepIndex: 2,
      persistBusy: true,
      celebratingCompletion: true,
    );

    final CoachTourState updated = initial.copyWith(
      stepIndex: 3,
      persistBusy: false,
    );

    expect(updated.isVisible, isTrue);
    expect(updated.stepIndex, 3);
    expect(updated.persistBusy, isFalse);
    expect(updated.celebratingCompletion, isTrue);
  });
}
