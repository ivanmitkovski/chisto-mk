import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/core/providers/home_providers.dart';
import 'package:chisto_mobile/core/providers/root_container.dart';
import 'package:chisto_mobile/features/notifications/data/notification_open_diagnostics.dart';
import 'package:chisto_mobile/features/notifications/data/notification_open_payload.dart';
import 'package:chisto_mobile/shared/current_user.dart';

enum _NotificationOpenChannel {
  remoteMessage,
  dataPayload,
}

class NotificationOpenRouter {
  const NotificationOpenRouter._();

  static void _pushNamedAfterFrame(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pushNamed(routeName, arguments: arguments);
    });
  }

  static void _navigateHomeAfterFrame(
    BuildContext context, {
    Object? arguments,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }
      AppRouter.navigateToHome(context, arguments: arguments);
    });
  }

  static void _navigateHomeMapFocusAfterFrame(
    BuildContext context, {
    required MapSiteFocusRouteArgs args,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }
      AppRouter.navigateToHomeMapFocus(context, args: args);
    });
  }

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
    final String? notificationId = data['notificationId'] as String?;
    final String? type = data['type'] as String?;
    if (notificationId != null && notificationId.isNotEmpty) {
      final notificationsRepo = readRoot(notificationsRepositoryProvider);
      // ignore: discarded_futures
      notificationsRepo.recordOpened(notificationId);
      if (type == 'EVENT_CHAT') {
        // ignore: discarded_futures
        notificationsRepo.markAsRead(notificationId);
      }
    }
    final String? siteId = data['siteId'] as String?;

    if (siteId != null && siteId.isNotEmpty) {
      _navigateHomeMapFocusAfterFrame(
        context,
        args: MapSiteFocusRouteArgs(siteId: siteId),
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
        _navigateHomeAfterFrame(context, arguments: 0);
        NotificationOpenDiagnostics.recordOpenSuccess(
          channel == _NotificationOpenChannel.remoteMessage ? 'push_home' : 'data_home',
        );
        return;
      case 'CLEANUP_EVENT':
        final String? eventId = data['eventId'] as String?;
        if (eventId != null &&
            eventId.isNotEmpty &&
            notificationOpenPayloadLooksLikeEventId(eventId)) {
          _pushNamedAfterFrame(
            context,
            AppRoutes.eventsDetail,
            arguments: EventRouteArguments(eventId: eventId),
          );
          NotificationOpenDiagnostics.recordOpenSuccess(
            channel == _NotificationOpenChannel.remoteMessage ? 'push_event_detail' : 'data_event_detail',
          );
          return;
        }
        _pushNamedAfterFrame(context, AppRoutes.homeEvents);
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
          _pushNamedAfterFrame(
            context,
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
        _pushNamedAfterFrame(context, AppRoutes.homeEvents);
        NotificationOpenDiagnostics.recordOpenSuccess(
          channel == _NotificationOpenChannel.remoteMessage ? 'push_events_fallback' : 'data_events_fallback',
        );
        return;
      default:
        _navigateHomeAfterFrame(context, arguments: 0);
        NotificationOpenDiagnostics.recordOpenSuccess(
          channel == _NotificationOpenChannel.remoteMessage ? 'push_default' : 'data_home',
        );
    }
  }
}
