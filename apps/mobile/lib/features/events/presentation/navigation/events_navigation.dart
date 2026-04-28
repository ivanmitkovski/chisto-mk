import 'dart:async';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/features/events/data/discovery_analytics.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/screens/organizer_toolkit/organizer_toolkit_screen.dart';
import 'package:flutter/material.dart';

/// Routes for the events feature. See `events_presentation_conventions.dart` for screen/sheet/footer tokens.
class EventsNavigation {
  const EventsNavigation._();

  /// [HomeShell] uses a nested [GoRouter] navigator without [Navigator.onGenerateRoute].
  /// Named routes from [AppRouter] live on [MaterialApp]'s navigator — use the root one.
  static NavigatorState _rootNavigator(BuildContext context) {
    return Navigator.of(context, rootNavigator: true);
  }

  static Future<EcoEvent?> openCreate(
    BuildContext context, {
    String? preselectedSiteId,
    String? preselectedSiteName,
    String? preselectedSiteImageUrl,
    double? preselectedSiteDistanceKm,
  }) {
    if (ServiceLocator.instance.isInitialized &&
        !ServiceLocator.instance.authState.isOrganizerCertified) {
      return _rootNavigator(context).push<EcoEvent?>(
        MaterialPageRoute<EcoEvent?>(
          builder: (_) => OrganizerToolkitScreen(
            onCertified: () {
              _rootNavigator(context).pushNamed<EcoEvent?>(
                AppRoutes.eventsCreate,
                arguments: EventCreateRouteArguments(
                  preselectedSiteId: preselectedSiteId,
                  preselectedSiteName: preselectedSiteName,
                  preselectedSiteImageUrl: preselectedSiteImageUrl,
                  preselectedSiteDistanceKm: preselectedSiteDistanceKm,
                ),
              );
            },
          ),
        ),
      );
    }
    return _rootNavigator(context).pushNamed<EcoEvent?>(
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
    unawaited(
      DiscoveryAnalytics.instance.maybeTrack(
        DiscoveryFunnelStep.detailView,
        eventId: eventId,
      ),
    );
    return _rootNavigator(context).pushNamed<void>(
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
    _rootNavigator(context).pushReplacement(
      AppRouter.eventDetailReplacementRoute(eventId),
    );
  }

  static Future<bool?> openAttendeeQrScanner(
    BuildContext context, {
    required String eventId,
  }) {
    return _rootNavigator(context).pushNamed<bool>(
      AppRoutes.eventsAttendeeCheckIn,
      arguments: EventRouteArguments(eventId: eventId),
    );
  }

  static Future<void> openOrganizerCheckIn(
    BuildContext context, {
    required String eventId,
  }) {
    return _rootNavigator(context).pushNamed<void>(
      AppRoutes.eventsOrganizerCheckIn,
      arguments: EventRouteArguments(eventId: eventId),
    );
  }

  static Future<void> openCleanupEvidence(
    BuildContext context, {
    required String eventId,
  }) {
    return _rootNavigator(context).pushNamed<void>(
      AppRoutes.eventsCleanupEvidence,
      arguments: EventRouteArguments(eventId: eventId),
    );
  }

  static Future<void> openImpactReceipt(
    BuildContext context, {
    required String eventId,
  }) {
    return _rootNavigator(context).pushNamed<void>(
      AppRoutes.eventsImpactReceipt,
      arguments: EventRouteArguments(eventId: eventId),
    );
  }

  static Future<void> openFeed(BuildContext context) {
    return _rootNavigator(context).pushNamed(AppRoutes.homeEvents);
  }

  static Future<void> openOrganizerDashboard(BuildContext context) {
    return _rootNavigator(context).pushNamed(AppRoutes.eventsOrganizerDashboard);
  }
}
