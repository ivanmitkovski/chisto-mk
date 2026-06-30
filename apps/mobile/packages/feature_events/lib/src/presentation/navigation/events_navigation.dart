import 'dart:async';

import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/presentation/navigation/organizer_certification_navigation.dart';
import 'package:feature_events/src/presentation/screens/organizer_toolkit/organizer_toolkit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Routes for the events feature. See `events_presentation_conventions.dart` for screen/sheet/footer tokens.
class EventsNavigation {
  const EventsNavigation._();

  static Future<EcoEvent?> openCreate(
    BuildContext context, {
    required WidgetRef ref,
    required AuthState auth,
    String? preselectedSiteId,
    String? preselectedSiteName,
    String? preselectedSiteImageUrl,
    double? preselectedSiteDistanceKm,
  }) async {
    if (!await ensureLocationEligibleForAction(context, ref)) {
      return null;
    }
    if (!context.mounted) {
      return null;
    }
    final EventCreateRouteArguments createArgs = EventCreateRouteArguments(
      preselectedSiteId: preselectedSiteId,
      preselectedSiteName: preselectedSiteName,
      preselectedSiteImageUrl: preselectedSiteImageUrl,
      preselectedSiteDistanceKm: preselectedSiteDistanceKm,
    );
    if (!auth.isOrganizerCertified) {
      bool wantsCreate = false;
      await Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: organizerCertificationToolkitRouteName,
          ),
          builder: (_) => OrganizerToolkitScreen(
            onProceedToCreate: () => wantsCreate = true,
          ),
        ),
      );
      if (!wantsCreate || !auth.isOrganizerCertified) {
        return Future<EcoEvent?>.value(null);
      }
    }
    return AppNavigation.pushCreateEvent(args: createArgs);
  }

  static Future<void> openDetail(
    BuildContext context, {
    required String eventId,
  }) {
    return AppNavigation.pushEventDetail(eventId: eventId);
  }

  static void replaceDetail(BuildContext context, {required String eventId}) {
    AppNavigation.replaceEventDetail(eventId: eventId);
  }

  static Future<bool?> openAttendeeQrScanner(
    BuildContext context, {
    required String eventId,
  }) {
    return AppNavigation.pushAttendeeCheckIn(eventId: eventId);
  }

  static Future<void> openOrganizerCheckIn(
    BuildContext context, {
    required String eventId,
  }) {
    return AppNavigation.pushOrganizerCheckIn(eventId: eventId);
  }

  static Future<void> openCleanupEvidence(
    BuildContext context, {
    required String eventId,
  }) {
    return AppNavigation.pushCleanupEvidence(eventId: eventId);
  }

  static Future<void> openImpactReceipt(
    BuildContext context, {
    required String eventId,
  }) {
    return AppNavigation.pushImpactReceipt(eventId: eventId);
  }

  static Future<void> openFeed(BuildContext context) {
    AppNavigation.navigateToHomeEvents();
    return Future<void>.value();
  }

  static Future<void> openOrganizerDashboard(BuildContext context) {
    return AppNavigation.pushOrganizerDashboard();
  }
}
