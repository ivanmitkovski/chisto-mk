import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:flutter/cupertino.dart';

/// Routes for the events feature. See `events_presentation_conventions.dart` for screen/sheet/footer tokens.
class EventsNavigation {
  const EventsNavigation._();

  static Future<EcoEvent?> openCreate(
    BuildContext context, {
    String? preselectedSiteId,
    String? preselectedSiteName,
    String? preselectedSiteImageUrl,
    double? preselectedSiteDistanceKm,
  }) {
    return Navigator.of(context).pushNamed<EcoEvent?>(
      AppRoutes.eventsCreate,
      arguments: EventCreateRouteArguments(
        preselectedSiteId: preselectedSiteId,
        preselectedSiteName: preselectedSiteName,
        preselectedSiteImageUrl: preselectedSiteImageUrl,
        preselectedSiteDistanceKm: preselectedSiteDistanceKm,
      ),
    );
  }

  static Future<void> openDetail(
    BuildContext context, {
    required String eventId,
  }) {
    return Navigator.of(context).pushNamed<void>(
      AppRoutes.eventsDetail,
      arguments: EventRouteArguments(eventId: eventId),
    );
  }

  /// Replaces the current detail route with another event (e.g. series sibling).
  ///
  /// Uses [AppRouter.eventDetailReplacementRoute] instead of [Navigator.pushReplacementNamed]
  /// so we do not run a Cupertino Hero handoff between two different `Hero` tags.
  static void replaceDetail(
    BuildContext context, {
    required String eventId,
  }) {
    Navigator.of(context).pushReplacement(
      AppRouter.eventDetailReplacementRoute(eventId),
    );
  }

  static Future<bool?> openAttendeeQrScanner(
    BuildContext context, {
    required String eventId,
  }) {
    return Navigator.of(context).pushNamed<bool>(
      AppRoutes.eventsAttendeeCheckIn,
      arguments: EventRouteArguments(eventId: eventId),
    );
  }

  static Future<void> openOrganizerCheckIn(
    BuildContext context, {
    required String eventId,
  }) {
    return Navigator.of(context).pushNamed<void>(
      AppRoutes.eventsOrganizerCheckIn,
      arguments: EventRouteArguments(eventId: eventId),
    );
  }

  static Future<void> openCleanupEvidence(
    BuildContext context, {
    required String eventId,
  }) {
    return Navigator.of(context).pushNamed<void>(
      AppRoutes.eventsCleanupEvidence,
      arguments: EventRouteArguments(eventId: eventId),
    );
  }

  static Future<void> openFeed(BuildContext context) {
    return Navigator.of(context).pushNamed(AppRoutes.homeEvents);
  }

  static Future<void> openOrganizerDashboard(BuildContext context) {
    return Navigator.of(context).pushNamed(AppRoutes.eventsOrganizerDashboard);
  }
}
