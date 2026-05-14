import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/features/onboarding/coach_tour_analytics.dart';
import 'package:chisto_mobile/features/onboarding/domain/coach_tour_step.dart';
import 'package:chisto_mobile/features/onboarding/domain/feature_guide_repository.dart';
import 'package:flutter/foundation.dart';

/// Drives the post-registration home coach overlay (step index + visibility).
class CoachTourController extends ChangeNotifier {
  CoachTourController({
    required FeatureGuideRepository repository,
    this.debugForceSessionEligible = false,
  }) : _repository = repository;

  final FeatureGuideRepository _repository;

  /// When true, [startIfEligible] skips [FeatureGuideRepository.shouldShowPostRegistrationGuide].
  /// [HomeShell] sets this from [CoachTourDebug.forceSessionEligible] (opt-in in debug only).
  final bool debugForceSessionEligible;

  bool _visible = false;
  int _stepIndex = 0;
  bool _persistBusy = false;
  bool _celebratingCompletion = false;
  int _completionCancelGeneration = 0;

  bool get isVisible => _visible;
  int get stepIndex => _stepIndex;
  int get stepCount => kCoachTourSteps.length;
  bool get isBusy => _persistBusy;
  bool get isCelebratingCompletion => _celebratingCompletion;

  CoachTourStep get currentStep => kCoachTourSteps[_stepIndex];
  bool get isLastStep => _stepIndex >= stepCount - 1;

  /// Starts the tour when [FeatureGuideRepository.shouldShowPostRegistrationGuide] is true,
  /// or when [debugForceSessionEligible] is true (opt-in debug override).
  Future<void> startIfEligible() async {
    if (_visible) {
      return;
    }
    if (debugForceSessionEligible) {
      _visible = true;
      _stepIndex = 0;
      CoachTourAnalytics.log(CoachTourAnalyticsEvent.started, stepIndex: 0);
      notifyListeners();
      return;
    }
    final bool show = await _repository.shouldShowPostRegistrationGuide();
    if (!show) {
      return;
    }
    _visible = true;
    _stepIndex = 0;
    CoachTourAnalytics.log(CoachTourAnalyticsEvent.started, stepIndex: 0);
    notifyListeners();
  }

  Future<void> skip() async {
    if (!_visible || _persistBusy) {
      return;
    }
    _persistBusy = true;
    notifyListeners();
    try {
      await _repository.markFeatureGuideCompleted();
      CoachTourAnalytics.log(
        CoachTourAnalyticsEvent.skipped,
        stepIndex: _stepIndex,
      );
      _visible = false;
    } finally {
      _persistBusy = false;
      notifyListeners();
    }
  }

  /// Advances to the next step. On the last step, use [completeWithCelebration] instead.
  void next() {
    if (!_visible || _persistBusy) {
      return;
    }
    if (isLastStep) {
      return;
    }
    _stepIndex++;
    CoachTourAnalytics.log(
      CoachTourAnalyticsEvent.advanced,
      stepIndex: _stepIndex,
    );
    notifyListeners();
  }

  /// Persists completion, keeps a celebration overlay for at least [coachCompletionMinHold*], then hides.
  ///
  /// Throws if [FeatureGuideRepository.markFeatureGuideCompleted] fails (host should show a snack).
  Future<void> completeWithCelebration({required bool reduceMotion}) async {
    if (!_visible || !isLastStep || _persistBusy) {
      return;
    }
    final int token = _completionCancelGeneration;
    _celebratingCompletion = true;
    _persistBusy = true;
    notifyListeners();
    await Future<void>.delayed(Duration.zero);
    final Stopwatch sw = Stopwatch()..start();
    try {
      await _repository.markFeatureGuideCompleted();
    } catch (e, st) {
      if (token == _completionCancelGeneration) {
        _celebratingCompletion = false;
        _persistBusy = false;
        notifyListeners();
      }
      Error.throwWithStackTrace(e, st);
    }
    final int minMs = reduceMotion
        ? AppMotion.coachCompletionMinHoldReduceMotion.inMilliseconds
        : AppMotion.coachCompletionMinHoldFull.inMilliseconds;
    final int remaining = minMs - sw.elapsedMilliseconds;
    if (remaining > 0) {
      await Future<void>.delayed(Duration(milliseconds: remaining));
    }
    if (token != _completionCancelGeneration) {
      return;
    }
    CoachTourAnalytics.log(
      CoachTourAnalyticsEvent.completed,
      stepIndex: _stepIndex,
    );
    _celebratingCompletion = false;
    _persistBusy = false;
    _visible = false;
    notifyListeners();
  }

  void hideWithoutPersisting() {
    if (_visible) {
      CoachTourAnalytics.log(CoachTourAnalyticsEvent.dismissedForDeepLink);
    }
    _completionCancelGeneration++;
    _celebratingCompletion = false;
    _visible = false;
    notifyListeners();
  }
}
