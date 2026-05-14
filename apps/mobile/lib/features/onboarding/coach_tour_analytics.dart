import 'package:flutter/foundation.dart';

/// Lightweight coach funnel logging (debug only; no PII).
enum CoachTourAnalyticsEvent {
  started,
  stepShown,
  advanced,
  completed,
  skipped,
  dismissedForDeepLink,
}

abstract final class CoachTourAnalytics {
  CoachTourAnalytics._();

  static void log(CoachTourAnalyticsEvent event, {int? stepIndex}) {
    if (!kDebugMode) {
      return;
    }
    final String suffix = stepIndex != null ? ' step=$stepIndex' : '';
    debugPrint('[CoachTour] ${event.name}$suffix');
  }
}
