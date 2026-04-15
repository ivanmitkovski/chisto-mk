import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/features/notifications/data/notification_open_diagnostics.dart';

class NotificationOpenRouter {
  const NotificationOpenRouter._();

  static void handleOpen(BuildContext context, RemoteMessage message) {
    NotificationOpenDiagnostics.recordOpenAttempt('push_remote');
    final Map<String, dynamic> data = message.data;
    final String? type = data['type'] as String?;
    final String? siteId = data['siteId'] as String?;

    if (siteId != null && siteId.isNotEmpty) {
      Navigator.of(context).pushNamed(
        AppRoutes.homeMapFocus,
        arguments: MapSiteFocusRouteArgs(siteId: siteId),
      );
      NotificationOpenDiagnostics.recordOpenSuccess('push_site_map_focus');
      return;
    }

    switch (type) {
      case 'REPORT_STATUS':
      case 'SITE_UPDATE':
      case 'UPVOTE':
      case 'COMMENT':
      case 'NEARBY_REPORT':
        Navigator.of(context).pushNamed(AppRoutes.home, arguments: 0);
        NotificationOpenDiagnostics.recordOpenSuccess('push_home');
        return;
      case 'CLEANUP_EVENT':
        final String? eventId = data['eventId'] as String?;
        if (eventId != null && eventId.isNotEmpty) {
          Navigator.of(context).pushNamed(
            AppRoutes.eventsDetail,
            arguments: EventRouteArguments(eventId: eventId),
          );
          NotificationOpenDiagnostics.recordOpenSuccess('push_event_detail');
          return;
        }
        Navigator.of(context).pushNamed(AppRoutes.homeEvents);
        NotificationOpenDiagnostics.recordOpenSuccess('push_events');
        return;
      case 'EVENT_CHAT':
        final String? chatEventId = data['eventId'] as String?;
        if (chatEventId != null && chatEventId.isNotEmpty) {
          Navigator.of(context).pushNamed(
            AppRoutes.eventChat,
            arguments: EventChatRouteArguments(
              eventId: chatEventId,
              eventTitle: '',
              isOrganizer: false,
            ),
          );
          NotificationOpenDiagnostics.recordOpenSuccess('push_event_chat');
          return;
        }
        Navigator.of(context).pushNamed(AppRoutes.homeEvents);
        NotificationOpenDiagnostics.recordOpenSuccess('push_events_fallback');
        return;
      default:
        Navigator.of(context).pushNamed(AppRoutes.home, arguments: 0);
        NotificationOpenDiagnostics.recordOpenSuccess('push_default');
    }
  }

  static void handleOpenFromData(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    NotificationOpenDiagnostics.recordOpenAttempt('push_data');
    final String? type = data['type'] as String?;
    final String? siteId = data['siteId'] as String?;

    if (siteId != null && siteId.isNotEmpty) {
      Navigator.of(context).pushNamed(
        AppRoutes.homeMapFocus,
        arguments: MapSiteFocusRouteArgs(siteId: siteId),
      );
      NotificationOpenDiagnostics.recordOpenSuccess('data_site_map_focus');
      return;
    }

    switch (type) {
      case 'CLEANUP_EVENT':
        final String? eventId = data['eventId'] as String?;
        if (eventId != null && eventId.isNotEmpty) {
          Navigator.of(context).pushNamed(
            AppRoutes.eventsDetail,
            arguments: EventRouteArguments(eventId: eventId),
          );
          NotificationOpenDiagnostics.recordOpenSuccess('data_event_detail');
          return;
        }
        Navigator.of(context).pushNamed(AppRoutes.homeEvents);
        NotificationOpenDiagnostics.recordOpenSuccess('data_events');
        return;
      case 'EVENT_CHAT':
        final String? chatEventId = data['eventId'] as String?;
        if (chatEventId != null && chatEventId.isNotEmpty) {
          Navigator.of(context).pushNamed(
            AppRoutes.eventChat,
            arguments: EventChatRouteArguments(
              eventId: chatEventId,
              eventTitle: '',
              isOrganizer: false,
            ),
          );
          NotificationOpenDiagnostics.recordOpenSuccess('data_event_chat');
          return;
        }
        Navigator.of(context).pushNamed(AppRoutes.homeEvents);
        NotificationOpenDiagnostics.recordOpenSuccess('data_events_fallback');
        return;
      default:
        Navigator.of(context).pushNamed(AppRoutes.home, arguments: 0);
        NotificationOpenDiagnostics.recordOpenSuccess('data_home');
    }
  }
}
