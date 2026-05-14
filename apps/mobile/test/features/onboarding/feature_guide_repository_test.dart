import 'package:chisto_mobile/features/onboarding/data/shared_prefs_feature_guide_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'SharedPrefsFeatureGuideRepository reads and writes per user id',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final SharedPrefsFeatureGuideRepository repo =
          SharedPrefsFeatureGuideRepository(
            prefs,
            currentUserId: () => 'user_a',
          );
      expect(await repo.hasCompletedFeatureGuide(), isFalse);
      await repo.markFeatureGuideCompleted();
      expect(await repo.hasCompletedFeatureGuide(), isTrue);

      final SharedPrefsFeatureGuideRepository repoB =
          SharedPrefsFeatureGuideRepository(
            prefs,
            currentUserId: () => 'user_b',
          );
      expect(await repoB.hasCompletedFeatureGuide(), isFalse);
    },
  );

  test(
    'shouldShowPostRegistrationGuide is true only when pending and not completed',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final SharedPrefsFeatureGuideRepository repo =
          SharedPrefsFeatureGuideRepository(
            prefs,
            currentUserId: () => 'user_x',
          );

      expect(await repo.shouldShowPostRegistrationGuide(), isFalse);

      await repo.markPostRegistrationGuidePending();
      expect(await repo.shouldShowPostRegistrationGuide(), isTrue);

      await repo.markFeatureGuideCompleted();
      expect(await repo.shouldShowPostRegistrationGuide(), isFalse);
      expect(await repo.hasCompletedFeatureGuide(), isTrue);
      expect(
        prefs.getBool('feature_guide_registration_pending_v1_user_x'),
        isNull,
      );
    },
  );

  test('markFeatureGuideCompleted clears pending', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final SharedPrefsFeatureGuideRepository repo =
        SharedPrefsFeatureGuideRepository(prefs, currentUserId: () => 'user_y');
    await repo.markPostRegistrationGuidePending();
    expect(
      prefs.getBool('feature_guide_registration_pending_v1_user_y'),
      isTrue,
    );

    await repo.markFeatureGuideCompleted();
    expect(
      prefs.getBool('feature_guide_registration_pending_v1_user_y'),
      isNull,
    );
    expect(await repo.hasCompletedFeatureGuide(), isTrue);
  });

  test('clearPostRegistrationGuidePending removes pending only', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final SharedPrefsFeatureGuideRepository repo =
        SharedPrefsFeatureGuideRepository(prefs, currentUserId: () => 'user_z');
    await repo.markPostRegistrationGuidePending();
    await repo.clearPostRegistrationGuidePending();
    expect(
      prefs.getBool('feature_guide_registration_pending_v1_user_z'),
      isNull,
    );
    expect(await repo.shouldShowPostRegistrationGuide(), isFalse);
  });

  test('markPostRegistrationGuidePending is no-op without user id', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final SharedPrefsFeatureGuideRepository repo =
        SharedPrefsFeatureGuideRepository(prefs, currentUserId: () => null);
    await repo.markPostRegistrationGuidePending();
    expect(
      prefs.getBool('feature_guide_registration_pending_v1_unknown'),
      isNull,
    );
    expect(await repo.shouldShowPostRegistrationGuide(), isFalse);
  });
}
