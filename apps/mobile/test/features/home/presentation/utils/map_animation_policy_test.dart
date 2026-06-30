import 'package:feature_home/src/presentation/utils/map_animation_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mapAnimationLevelForSiteCount uses graded thresholds', () {
    expect(mapAnimationLevelForSiteCount(80), MapAnimationLevel.full);
    expect(mapAnimationLevelForSiteCount(120), MapAnimationLevel.full);
    expect(mapAnimationLevelForSiteCount(121), MapAnimationLevel.motionOnly);
    expect(mapAnimationLevelForSiteCount(220), MapAnimationLevel.motionOnly);
    expect(mapAnimationLevelForSiteCount(221), MapAnimationLevel.static);
  });

  test('mapReduceAnimations only at static tier', () {
    expect(
      mapReduceAnimations(disableAnimations: false, filteredSiteCount: 150),
      isFalse,
    );
    expect(
      mapReduceAnimations(disableAnimations: false, filteredSiteCount: 300),
      isTrue,
    );
    expect(
      mapReduceAnimations(disableAnimations: true, filteredSiteCount: 50),
      isTrue,
    );
  });
}
