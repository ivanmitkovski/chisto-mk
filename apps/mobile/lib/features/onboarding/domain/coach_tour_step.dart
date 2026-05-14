import 'package:chisto_mobile/features/onboarding/domain/coach_tour_illustration.dart';

/// Spotlight target for a coach step (maps to [HomeShellCoachKeys]).
enum CoachTourTarget {
  /// Centered card only; full scrim without a cutout.
  none,

  navHome,
  navReports,
  navMap,
  navEvents,
  centralFab,
  profileAvatar,
}

class CoachTourStep {
  const CoachTourStep({
    required this.requiredTabIndex,
    required this.target,
    this.illustration = CoachTourIllustrationKind.none,
  });

  /// Branch index for [StatefulNavigationShell.goBranch] (0 feed … 3 events).
  final int requiredTabIndex;
  final CoachTourTarget target;

  /// Optional hero icon for the step card (accessibility: copy remains primary).
  final CoachTourIllustrationKind illustration;
}

/// Ordered coach tour: welcome → map → reports → FAB → events → profile.
const List<CoachTourStep> kCoachTourSteps = <CoachTourStep>[
  CoachTourStep(
    requiredTabIndex: 0,
    target: CoachTourTarget.none,
    illustration: CoachTourIllustrationKind.wavingHand,
  ),
  CoachTourStep(
    requiredTabIndex: 2,
    target: CoachTourTarget.navMap,
    illustration: CoachTourIllustrationKind.mapExplore,
  ),
  CoachTourStep(
    requiredTabIndex: 1,
    target: CoachTourTarget.navReports,
    illustration: CoachTourIllustrationKind.assignment,
  ),
  CoachTourStep(
    requiredTabIndex: 1,
    target: CoachTourTarget.centralFab,
    illustration: CoachTourIllustrationKind.addCircle,
  ),
  CoachTourStep(
    requiredTabIndex: 3,
    target: CoachTourTarget.navEvents,
    illustration: CoachTourIllustrationKind.event,
  ),
  CoachTourStep(
    requiredTabIndex: 0,
    target: CoachTourTarget.profileAvatar,
    illustration: CoachTourIllustrationKind.person,
  ),
];
