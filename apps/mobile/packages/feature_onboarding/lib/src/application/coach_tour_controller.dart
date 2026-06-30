import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/theme/app_motion.dart';
import 'package:feature_onboarding/src/application/coach_tour_analytics.dart';
import 'package:feature_onboarding/src/application/coach_tour_state.dart';
import 'package:feature_onboarding/src/debug/coach_tour_debug.dart';
import 'package:feature_onboarding/src/domain/coach_tour_step.dart';
import 'package:feature_onboarding/src/domain/feature_guide_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'coach_tour_controller.g.dart';

/// Drives the post-registration home coach overlay (step index + visibility).
@Riverpod(keepAlive: true)
class CoachTourController extends _$CoachTourController {
  late final FeatureGuideRepository _repository;
  int _completionCancelGeneration = 0;
  bool _alive = true;

  @override
  CoachTourState build() {
    _alive = true;
    _repository = ref.watch(featureGuideRepositoryProvider);
    ref.onDispose(() {
      _alive = false;
    });
    return const CoachTourState();
  }

  bool get debugForceSessionEligible => CoachTourDebug.forceSessionEligible;

  bool get isVisible => state.isVisible;
  int get stepIndex => state.stepIndex;
  int get stepCount => kCoachTourSteps.length;
  bool get isBusy => state.persistBusy;
  bool get isCelebratingCompletion => state.celebratingCompletion;

  CoachTourStep get currentStep => kCoachTourSteps[state.stepIndex];
  bool get isLastStep => state.stepIndex >= stepCount - 1;

  /// Starts the tour when [FeatureGuideRepository.shouldShowPostRegistrationGuide] is true,
  /// or when [debugForceSessionEligible] is true (opt-in debug override).
  Future<void> startIfEligible() async {
    if (state.isVisible) {
      return;
    }
    if (debugForceSessionEligible) {
      state = state.copyWith(isVisible: true, stepIndex: 0);
      CoachTourAnalytics.log(CoachTourAnalyticsEvent.started, stepIndex: 0);
      return;
    }
    final bool show = await _repository.shouldShowPostRegistrationGuide();
    if (!show || !_alive) {
      return;
    }
    state = state.copyWith(isVisible: true, stepIndex: 0);
    CoachTourAnalytics.log(CoachTourAnalyticsEvent.started, stepIndex: 0);
  }

  Future<void> skip() async {
    if (!state.isVisible || state.persistBusy) {
      return;
    }
    state = state.copyWith(persistBusy: true);
    try {
      await _repository.markFeatureGuideCompleted();
      CoachTourAnalytics.log(
        CoachTourAnalyticsEvent.skipped,
        stepIndex: state.stepIndex,
      );
      if (_alive) {
        state = state.copyWith(isVisible: false);
      }
    } finally {
      if (_alive) {
        state = state.copyWith(persistBusy: false);
      }
    }
  }

  /// Advances to the next step. On the last step, use [completeWithCelebration] instead.
  void next() {
    if (!state.isVisible || state.persistBusy) {
      return;
    }
    if (isLastStep) {
      return;
    }
    final int nextIndex = state.stepIndex + 1;
    state = state.copyWith(stepIndex: nextIndex);
    CoachTourAnalytics.log(
      CoachTourAnalyticsEvent.advanced,
      stepIndex: nextIndex,
    );
  }

  /// Persists completion, keeps a celebration overlay for at least [coachCompletionMinHold*], then hides.
  ///
  /// Throws if [FeatureGuideRepository.markFeatureGuideCompleted] fails (host should show a snack).
  Future<void> completeWithCelebration({required bool reduceMotion}) async {
    if (!state.isVisible || !isLastStep || state.persistBusy) {
      return;
    }
    final int token = _completionCancelGeneration;
    state = state.copyWith(celebratingCompletion: true, persistBusy: true);
    await Future<void>.delayed(Duration.zero);
    final Stopwatch sw = Stopwatch()..start();
    try {
      await _repository.markFeatureGuideCompleted();
    } catch (e, st) {
      if (token == _completionCancelGeneration && _alive) {
        state = state.copyWith(
          celebratingCompletion: false,
          persistBusy: false,
        );
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
    if (token != _completionCancelGeneration || !_alive) {
      return;
    }
    CoachTourAnalytics.log(
      CoachTourAnalyticsEvent.completed,
      stepIndex: state.stepIndex,
    );
    state = state.copyWith(
      celebratingCompletion: false,
      persistBusy: false,
      isVisible: false,
    );
  }

  void hideWithoutPersisting() {
    if (state.isVisible) {
      CoachTourAnalytics.log(CoachTourAnalyticsEvent.dismissedForDeepLink);
    }
    _completionCancelGeneration++;
    state = state.copyWith(celebratingCompletion: false, isVisible: false);
  }
}
