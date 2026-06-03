import 'package:flutter/material.dart';

/// Route name for the organizer toolkit modal pushed on the root navigator.
const String organizerCertificationToolkitRouteName =
    'organizer_certification_toolkit';

/// Route name for the quiz screen pushed on top of the toolkit flow.
const String organizerCertificationQuizRouteName =
    'organizer_certification_quiz';

bool _isOrganizerCertificationRoute(Route<dynamic> route) {
  final String? name = route.settings.name;
  return name == organizerCertificationToolkitRouteName ||
      name == organizerCertificationQuizRouteName;
}

/// Removes toolkit and quiz overlays from the root navigator.
///
/// Used when the user finishes certification and continues to create an event.
/// Without this, [CreateEventSheet] pop would reveal the toolkit tutorial again.
void dismissOrganizerCertificationFlow(BuildContext context) {
  final NavigatorState? nav = Navigator.maybeOf(context, rootNavigator: true);
  if (nav == null) {
    return;
  }
  nav.popUntil(
    (Route<dynamic> route) => !_isOrganizerCertificationRoute(route),
  );
}
