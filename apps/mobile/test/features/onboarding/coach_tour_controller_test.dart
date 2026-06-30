import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:feature_onboarding/src/application/coach_tour_controller.dart';
import 'package:feature_onboarding/src/domain/coach_tour_step.dart';
import 'package:feature_onboarding/src/domain/feature_guide_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

CoachTourController _coach(ProviderContainer container) =>
    container.read(coachTourControllerProvider.notifier);

ProviderContainer _coachContainer({FeatureGuideRepository? repo}) {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      featureGuideRepositoryProvider.overrideWithValue(repo ?? _FakeRepo()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('startIfEligible shows when repository says pending', () async {
    final _FakeRepo repo = _FakeRepo();
    final ProviderContainer container = _coachContainer(repo: repo);
    final CoachTourController c = _coach(container);
    await c.startIfEligible();
    expect(c.isVisible, isTrue);
    expect(c.stepIndex, 0);
  });

  test('startIfEligible does nothing when shouldShow is false', () async {
    final _FakeRepo repo = _FakeRepo()..pending = false;
    final ProviderContainer container = _coachContainer(repo: repo);
    final CoachTourController c = _coach(container);
    await c.startIfEligible();
    expect(c.isVisible, isFalse);
  });

  test(
    'startIfEligible shows step 0 and advances through last step with celebration',
    () async {
      final _FakeRepo repo = _FakeRepo();
      final ProviderContainer container = _coachContainer(repo: repo);
      final CoachTourController c = _coach(container);
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
    final ProviderContainer container = _coachContainer(repo: repo);
    final CoachTourController c = _coach(container);
    await c.startIfEligible();
    await c.skip();
    expect(c.isVisible, isFalse);
    expect(repo.markCompletedCalls, 1);
  });

  test('skip restores tour when persist fails', () async {
    final _FakeRepo repo = _FakeRepo()..throwOnMark = true;
    final ProviderContainer container = _coachContainer(repo: repo);
    final CoachTourController c = _coach(container);
    await c.startIfEligible();
    await expectLater(c.skip(), throwsA(isA<StateError>()));
    expect(c.isVisible, isTrue);
    expect(c.isBusy, isFalse);
    expect(repo.markCompletedCalls, 1);
  });

  test('completeWithCelebration restores tour when persist fails', () async {
    final _FakeRepo repo = _FakeRepo()..throwOnMark = true;
    final ProviderContainer container = _coachContainer(repo: repo);
    final CoachTourController c = _coach(container);
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

  test('startIfEligible is no-op when tour already visible', () async {
    final _FakeRepo repo = _FakeRepo();
    final ProviderContainer container = _coachContainer(repo: repo);
    final CoachTourController c = _coach(container);
    await c.startIfEligible();
    c.next();
    await c.startIfEligible();
    expect(c.stepIndex, 1);
  });

  test('next does not advance past last step', () async {
    final _FakeRepo repo = _FakeRepo();
    final ProviderContainer container = _coachContainer(repo: repo);
    final CoachTourController c = _coach(container);
    await c.startIfEligible();
    for (int i = 0; i < kCoachTourSteps.length - 1; i++) {
      c.next();
    }
    expect(c.isLastStep, isTrue);
    c.next();
    expect(c.stepIndex, kCoachTourSteps.length - 1);
  });

  test('hideWithoutPersisting hides without marking completed', () async {
    final _FakeRepo repo = _FakeRepo();
    final ProviderContainer container = _coachContainer(repo: repo);
    final CoachTourController c = _coach(container);
    await c.startIfEligible();
    c.hideWithoutPersisting();
    expect(c.isVisible, isFalse);
    expect(repo.markCompletedCalls, 0);
    expect(repo.completed, isFalse);
  });
}
