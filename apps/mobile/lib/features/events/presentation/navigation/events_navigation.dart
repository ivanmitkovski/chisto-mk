import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:flutter/cupertino.dart';

class EventsNavigation {
  const EventsNavigation._();

  static Future<EcoEvent?> openCreate(
    BuildContext context, {
    String? preselectedSiteId,
    String? preselectedSiteName,
    String? preselectedSiteImageUrl,
    double? preselectedSiteDistanceKm,
  }) {
    return Navigator.of(context).pushNamed<EcoEvent>(
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
}
