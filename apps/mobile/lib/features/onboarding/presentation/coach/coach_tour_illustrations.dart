import 'package:chisto_mobile/features/onboarding/domain/coach_tour_illustration.dart';
import 'package:flutter/material.dart';

IconData? coachTourIllustrationIcon(CoachTourIllustrationKind kind) {
  switch (kind) {
    case CoachTourIllustrationKind.none:
      return null;
    case CoachTourIllustrationKind.wavingHand:
      return Icons.waving_hand;
    case CoachTourIllustrationKind.mapExplore:
      return Icons.map_outlined;
    case CoachTourIllustrationKind.assignment:
      return Icons.assignment_outlined;
    case CoachTourIllustrationKind.addCircle:
      return Icons.add_circle_outline;
    case CoachTourIllustrationKind.event:
      return Icons.event_outlined;
    case CoachTourIllustrationKind.person:
      return Icons.person_outline;
  }
}
