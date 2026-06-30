import 'package:chisto_infrastructure/core/navigation/app_navigator_key.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/presentation/organizer_checkin/organizer_checkin_screen.dart';
import 'package:feature_events/src/presentation/screens/attendee_qr_scanner_screen.dart';
import 'package:feature_events/src/presentation/screens/create_event_sheet.dart';
import 'package:feature_events/src/presentation/screens/event_chat_screen.dart';
import 'package:feature_events/src/presentation/screens/event_cleanup_evidence_screen.dart';
import 'package:feature_events/src/presentation/screens/event_detail_screen.dart';
import 'package:feature_events/src/presentation/screens/event_impact_receipt_screen.dart';
import 'package:feature_events/src/presentation/screens/organizer_dashboard_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

/// Root-level go_router routes owned by the events feature.
List<RouteBase> buildEventsRoutes() {
  return <RouteBase>[
    GoRoute(
      path: AppRoutes.eventsCreate,
      parentNavigatorKey: appRootNavigatorKey,
      pageBuilder: (BuildContext context, GoRouterState state) {
        final EventCreateRouteArguments args =
            state.extra is EventCreateRouteArguments
            ? state.extra! as EventCreateRouteArguments
            : const EventCreateRouteArguments();
        return CupertinoPage<EcoEvent?>(
          key: state.pageKey,
          child: CreateEventSheet(
            preselectedSiteId: args.preselectedSiteId,
            preselectedSiteName: args.preselectedSiteName,
            preselectedSiteImageUrl: args.preselectedSiteImageUrl,
            preselectedSiteDistanceKm: args.preselectedSiteDistanceKm,
          ),
        );
      },
    ),
    GoRoute(
      path: '${AppRoutes.eventsDetail}/:eventId',
      parentNavigatorKey: appRootNavigatorKey,
      pageBuilder: (BuildContext context, GoRouterState state) {
        final String eventId = state.pathParameters['eventId'] ?? '';
        final bool enableThumbnailHero = eventDetailEnableThumbnailHero(
          state.extra,
        );
        final Widget child = EventDetailScreen(
          eventId: eventId,
          enableThumbnailHero: enableThumbnailHero,
        );
        if (!enableThumbnailHero) {
          return NoTransitionPage<void>(key: state.pageKey, child: child);
        }
        return CupertinoPage<void>(key: state.pageKey, child: child);
      },
    ),
    GoRoute(
      path: AppRoutes.eventsAttendeeCheckIn,
      parentNavigatorKey: appRootNavigatorKey,
      pageBuilder: (BuildContext context, GoRouterState state) {
        final EventRouteArguments args = eventRouteArgsFrom(state);
        return CupertinoPage<bool>(
          key: state.pageKey,
          child: AttendeeQrScannerScreen(eventId: args.eventId),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.eventsOrganizerCheckIn,
      parentNavigatorKey: appRootNavigatorKey,
      pageBuilder: (BuildContext context, GoRouterState state) {
        final EventRouteArguments args = eventRouteArgsFrom(state);
        return CupertinoPage<void>(
          key: state.pageKey,
          child: OrganizerCheckInScreen(eventId: args.eventId),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.eventsCleanupEvidence,
      parentNavigatorKey: appRootNavigatorKey,
      pageBuilder: (BuildContext context, GoRouterState state) {
        final EventRouteArguments args = eventRouteArgsFrom(state);
        return CupertinoPage<void>(
          key: state.pageKey,
          child: EventCleanupEvidenceScreen(eventId: args.eventId),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.eventsImpactReceipt,
      parentNavigatorKey: appRootNavigatorKey,
      pageBuilder: (BuildContext context, GoRouterState state) {
        final EventRouteArguments args = eventRouteArgsFrom(state);
        return CupertinoPage<void>(
          key: state.pageKey,
          child: EventImpactReceiptScreen(eventId: args.eventId),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.eventsOrganizerDashboard,
      parentNavigatorKey: appRootNavigatorKey,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return CupertinoPage<void>(
          key: state.pageKey,
          child: const OrganizerDashboardScreen(),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.eventChat,
      parentNavigatorKey: appRootNavigatorKey,
      pageBuilder: (BuildContext context, GoRouterState state) {
        final EventChatRouteArguments args =
            state.extra is EventChatRouteArguments
            ? state.extra! as EventChatRouteArguments
            : EventChatRouteArguments(
                eventId: '',
                eventTitle: '',
                isOrganizer: false,
              );
        return CupertinoPage<void>(
          key: state.pageKey,
          child: EventChatScreen(
            eventId: args.eventId,
            eventTitle: args.eventTitle,
            isOrganizer: args.isOrganizer,
            readSyncCompleter: args.readSyncCompleter,
          ),
        );
      },
    ),
  ];
}

bool eventDetailEnableThumbnailHero(Object? extra) {
  if (extra is EventRouteArguments) {
    return extra.enableThumbnailHero;
  }
  return true;
}

EventRouteArguments eventRouteArgsFrom(GoRouterState state) {
  if (state.extra is EventRouteArguments) {
    return state.extra! as EventRouteArguments;
  }
  final String? eventId = state.pathParameters['eventId'];
  if (eventId != null && eventId.isNotEmpty) {
    return EventRouteArguments(eventId: eventId);
  }
  return const EventRouteArguments(eventId: '');
}
