/// Immutable coach overlay state for [CoachTourController].
class CoachTourState {
  const CoachTourState({
    this.isVisible = false,
    this.stepIndex = 0,
    this.persistBusy = false,
    this.celebratingCompletion = false,
  });

  final bool isVisible;
  final int stepIndex;
  final bool persistBusy;
  final bool celebratingCompletion;

  bool get isCelebratingCompletion => celebratingCompletion;

  CoachTourState copyWith({
    bool? isVisible,
    int? stepIndex,
    bool? persistBusy,
    bool? celebratingCompletion,
  }) {
    return CoachTourState(
      isVisible: isVisible ?? this.isVisible,
      stepIndex: stepIndex ?? this.stepIndex,
      persistBusy: persistBusy ?? this.persistBusy,
      celebratingCompletion:
          celebratingCompletion ?? this.celebratingCompletion,
    );
  }
}
