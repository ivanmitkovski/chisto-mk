import 'package:feature_onboarding/src/application/coach_tour_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CoachTourAnalytics.log does not throw in debug tests', () {
    expect(kDebugMode, isTrue);
    expect(
      () =>
          CoachTourAnalytics.log(CoachTourAnalyticsEvent.started, stepIndex: 0),
      returnsNormally,
    );
    expect(
      () => CoachTourAnalytics.log(CoachTourAnalyticsEvent.completed),
      returnsNormally,
    );
  });

  test('CoachTourAnalyticsEvent covers funnel steps', () {
    expect(CoachTourAnalyticsEvent.values, hasLength(6));
    expect(
      CoachTourAnalyticsEvent.values,
      contains(CoachTourAnalyticsEvent.skipped),
    );
    expect(
      CoachTourAnalyticsEvent.values,
      contains(CoachTourAnalyticsEvent.dismissedForDeepLink),
    );
  });
}
