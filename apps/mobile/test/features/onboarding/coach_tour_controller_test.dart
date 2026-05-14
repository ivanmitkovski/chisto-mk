import 'package:chisto_mobile/features/onboarding/application/coach_tour_controller.dart';
import 'package:chisto_mobile/features/onboarding/domain/coach_tour_step.dart';
import 'package:chisto_mobile/features/onboarding/domain/feature_guide_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements FeatureGuideRepository {
  bool completed = false;
  bool pending = true;
  int markCompletedCalls = 0;
  bool throwOnMark = false;

  @override
  Future<void> clearPostRegistrationGuidePending() async {}

  @override
  Future<bool> hasCompletedFeatureGuide() async => completed;

  @override
  Future<void> markFeatureGuideCompleted() async {
    markCompletedCalls++;
    if (throwOnMark) {
      throw StateError('persist failed');
    }
    completed = true;
  }

  @override
  Future<void> markPostRegistrationGuidePending() async {}

  @override
  Future<bool> shouldShowPostRegistrationGuide() async => pending && !completed;
}

void main() {
  test(
    'startIfEligible bypasses repository when debugForceSessionEligible',
    () async {
      final _FakeRepo repo = _FakeRepo()..pending = false;
      final CoachTourController c = CoachTourController(
        repository: repo,
        debugForceSessionEligible: true,
      );
      await c.startIfEligible();
      expect(c.isVisible, isTrue);
      expect(c.stepIndex, 0);
    },
  );

  test('startIfEligible does nothing when shouldShow is false', () async {
    final _FakeRepo repo = _FakeRepo()..pending = false;
    final CoachTourController c = CoachTourController(repository: repo);
    await c.startIfEligible();
    expect(c.isVisible, isFalse);
  });

  test(
    'startIfEligible shows step 0 and advances through last step with celebration',
    () async {
      final _FakeRepo repo = _FakeRepo();
      final CoachTourController c = CoachTourController(repository: repo);
      await c.startIfEligible();
      expect(c.isVisible, isTrue);
      expect(c.stepIndex, 0);
      expect(c.currentStep, kCoachTourSteps.first);

      for (int i = 0; i < kCoachTourSteps.length - 1; i++) {
        c.next();
        expect(c.stepIndex, i + 1);
        expect(c.isVisible, isTrue);
      }
      expect(c.isLastStep, isTrue);
      final Future<void> done = c.completeWithCelebration(reduceMotion: true);
      expect(c.isCelebratingCompletion, isTrue);
      await done;
      expect(c.isVisible, isFalse);
      expect(c.isCelebratingCompletion, isFalse);
      expect(repo.markCompletedCalls, 1);
      expect(repo.completed, isTrue);
    },
  );

  test('skip marks completed and hides', () async {
    final _FakeRepo repo = _FakeRepo();
    final CoachTourController c = CoachTourController(repository: repo);
    await c.startIfEligible();
    await c.skip();
    expect(c.isVisible, isFalse);
    expect(repo.markCompletedCalls, 1);
  });

  test('completeWithCelebration restores tour when persist fails', () async {
    final _FakeRepo repo = _FakeRepo()..throwOnMark = true;
    final CoachTourController c = CoachTourController(repository: repo);
    await c.startIfEligible();
    for (int i = 0; i < kCoachTourSteps.length - 1; i++) {
      c.next();
    }
    await expectLater(
      c.completeWithCelebration(reduceMotion: true),
      throwsA(isA<StateError>()),
    );
    expect(c.isVisible, isTrue);
    expect(c.isCelebratingCompletion, isFalse);
    expect(c.isBusy, isFalse);
    expect(repo.markCompletedCalls, 1);
  });
}
