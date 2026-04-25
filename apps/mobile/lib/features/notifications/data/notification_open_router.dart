import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/notifications/data/notification_open_diagnostics.dart';
import 'package:chisto_mobile/features/notifications/data/notification_open_payload.dart';
import 'package:chisto_mobile/shared/current_user.dart';

enum _NotificationOpenChannel {
  remoteMessage,
  dataPayload,
}

class NotificationOpenRouter {
  const NotificationOpenRouter._();

  static void handleOpen(BuildContext context, RemoteMessage message) {
    NotificationOpenDiagnostics.recordOpenAttempt('push_remote');
    _routeFromPayload(
      context,
      message.data,
      channel: _NotificationOpenChannel.remoteMessage,
      notificationTitle: message.notification?.title,
    );
  }

  static void handleOpenFromData(
    BuildContext context,
    Map<String, dynamic> data, {
    String? notificationTitle,
  }) {
    NotificationOpenDiagnostics.recordOpenAttempt('push_data');
    _routeFromPayload(
      context,
      data,
      channel: _NotificationOpenChannel.dataPayload,
      notificationTitle: notificationTitle,
    );
  }

  static void _routeFromPayload(
    BuildContext context,
    Map<String, dynamic> data, {
    required _NotificationOpenChannel channel,
    String? notificationTitle,
  }) {
    final String? type = data['type'] as String?;
    final String? siteId = data['siteId'] as String?;

    if (siteId != null && siteId.isNotEmpty) {
      Navigator.of(context).pushNamed(
        AppRoutes.homeMapFocus,
        arguments: MapSiteFocusRouteArgs(siteId: siteId),
      );
      NotificationOpenDiagnostics.recordOpenSuccess(
        channel == _NotificationOpenChannel.remoteMessage ? 'push_site_map_focus' : 'data_site_map_focus',
      );
      return;
    }

    switch (type) {
      case 'REPORT_STATUS':
      case 'SITE_UPDATE':
      case 'UPVOTE':
      case 'COMMENT':
      case 'NEARBY_REPORT':
        Navigator.of(context).pushNamed(AppRoutes.home, arguments: 0);
        NotificationOpenDiagnostics.recordOpenSuccess(
          channel == _NotificationOpenChannel.remoteMessage ? 'push_home' : 'data_home',
        );
        return;
      case 'CLEANUP_EVENT':
        final String? eventId = data['eventId'] as String?;
        if (eventId != null &&
            eventId.isNotEmpty &&
            notificationOpenPayloadLooksLikeEventId(eventId)) {
          Navigator.of(context).pushNamed(
            AppRoutes.eventsDetail,
            arguments: EventRouteArguments(eventId: eventId),
          );
          NotificationOpenDiagnostics.recordOpenSuccess(
            channel == _NotificationOpenChannel.remoteMessage ? 'push_event_detail' : 'data_event_detail',
          );
          return;
        }
        Navigator.of(context).pushNamed(AppRoutes.homeEvents);
        NotificationOpenDiagnostics.recordOpenSuccess(
          channel == _NotificationOpenChannel.remoteMessage ? 'push_events' : 'data_events',
        );
        return;
      case 'EVENT_CHAT':
        final String? chatEventId = data['eventId'] as String?;
        if (chatEventId != null &&
            chatEventId.isNotEmpty &&
            notificationOpenPayloadLooksLikeEventId(chatEventId)) {
          final String eventTitle = notificationOpenResolveChatBarTitle(
            data: data,
            notificationTitle: notificationTitle,
            cachedEventTitle:
                EventsRepositoryRegistry.instance.findById(chatEventId)?.title,
          );
          final EcoEvent? cachedEvent =
              EventsRepositoryRegistry.instance.findById(chatEventId);
          final bool isOrganizer = cachedEvent != null &&
              cachedEvent.organizerId.isNotEmpty &&
              cachedEvent.organizerId == CurrentUser.id;
          Navigator.of(context).pushNamed(
            AppRoutes.eventChat,
            arguments: EventChatRouteArguments(
              eventId: chatEventId,
              eventTitle: eventTitle,
              isOrganizer: isOrganizer,
            ),
          );
          NotificationOpenDiagnostics.recordOpenSuccess(
            channel == _NotificationOpenChannel.remoteMessage ? 'push_event_chat' : 'data_event_chat',
          );
          return;
        }
        Navigator.of(context).pushNamed(AppRoutes.homeEvents);
        NotificationOpenDiagnostics.recordOpenSuccess(
          channel == _NotificationOpenChannel.remoteMessage ? 'push_events_fallback' : 'data_events_fallback',
        );
        return;
      default:
        Navigator.of(context).pushNamed(AppRoutes.home, arguments: 0);
        NotificationOpenDiagnostics.recordOpenSuccess(
          channel == _NotificationOpenChannel.remoteMessage ? 'push_default' : 'data_home',
        );
    }
  }
}
