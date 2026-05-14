import 'package:flutter/foundation.dart';

/// Debug-only helpers for the home coach overlay.
///
/// **Default:** coach follows [FeatureGuideRepository.shouldShowPostRegistrationGuide]
/// (once after registration, then never again).
///
/// **Local QA:** pass `--dart-define=COACH_DEBUG_FORCE_COACH=true` so the coach
/// can start even when the guide is not pending, and [InitialRouteScreen] will
/// still request a coach start on cold launch.
///
/// **Release / profile:** [kDebugMode] is false, so these flags are always off.
abstract final class CoachTourDebug {
  CoachTourDebug._();

  static const bool _forceCoach = bool.fromEnvironment(
    'COACH_DEBUG_FORCE_COACH',
    defaultValue: false,
  );

  /// When true, [CoachTourController.startIfEligible] skips repository eligibility.
  static bool get forceSessionEligible => kDebugMode && _forceCoach;

  /// When true, [InitialRouteScreen] passes [HomeRouteArgs.startCoachTour] even
  /// if the repository says the guide is not pending.
  static bool get forceHomeStartCoachArgs => kDebugMode && _forceCoach;
}
