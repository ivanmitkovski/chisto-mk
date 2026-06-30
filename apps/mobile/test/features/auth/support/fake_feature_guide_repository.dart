import 'package:feature_onboarding/src/domain/feature_guide_repository.dart';

class FakeFeatureGuideRepository implements FeatureGuideRepository {
  FakeFeatureGuideRepository({
    this.completed = false,
    this.postRegistrationPending = false,
  });

  bool completed;
  bool postRegistrationPending;

  @override
  Future<bool> hasCompletedFeatureGuide() async => completed;

  @override
  Future<void> markFeatureGuideCompleted() async {
    completed = true;
    postRegistrationPending = false;
  }

  @override
  Future<bool> shouldShowPostRegistrationGuide() async =>
      postRegistrationPending && !completed;

  @override
  Future<void> markPostRegistrationGuidePending() async {
    postRegistrationPending = true;
  }

  @override
  Future<void> clearPostRegistrationGuidePending() async {
    postRegistrationPending = false;
  }
}
