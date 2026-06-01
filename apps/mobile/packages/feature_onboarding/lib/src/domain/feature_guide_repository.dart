/// Persists post-registration feature guide eligibility and completion (per user id).
abstract class FeatureGuideRepository {
  Future<bool> hasCompletedFeatureGuide();

  Future<void> markFeatureGuideCompleted();

  /// True when the user finished sign-up (location) and has not finished the guide.
  Future<bool> shouldShowPostRegistrationGuide();

  /// Call from [LocationScreen] after sign-up only — not from sign-in.
  Future<void> markPostRegistrationGuidePending();

  Future<void> clearPostRegistrationGuidePending();
}
