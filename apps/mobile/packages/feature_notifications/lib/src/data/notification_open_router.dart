import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:chisto_infrastructure/shared/current_user.dart';
import 'package:feature_events/feature_events.dart';
import 'package:feature_notifications/src/application/notifications_providers.dart';
import 'package:feature_notifications/src/data/notification_open_diagnostics.dart';
import 'package:feature_notifications/src/data/notification_open_payload.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

enum _NotificationOpenChannel { remoteMessage, dataPayload }

class NotificationOpenRouter {
  const NotificationOpenRouter._();

  static void _afterFrame(void Function() action) {
    WidgetsBinding.instance.addPostFrameCallback((_) => action());
  }

  static void handleOpen(BuildContext context, RemoteMessage message) {
    NotificationOpenDiagnostics.recordOpenAttempt('push_remote');
    _routeFromPayload(
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
      data,
      channel: _NotificationOpenChannel.dataPayload,
      notificationTitle: notificationTitle,
    );
  }

  static void _routeFromPayload(
    Map<String, dynamic> data, {
    required _NotificationOpenChannel channel,
    String? notificationTitle,
  }) {
    final String? notificationId = data['notificationId'] as String?;
    final String? type = data['type'] as String?;
    if (notificationId != null && notificationId.isNotEmpty) {
      final notificationsRepo = readRoot(notificationsRepositoryProvider);
      // ignore: discarded_futures, fire-and-forget open analytics
      notificationsRepo.recordOpened(notificationId);
      if (type == 'EVENT_CHAT') {
        // ignore: discarded_futures, fire-and-forget mark-as-read
        notificationsRepo.markAsRead(notificationId);
      }
    }
    final String? siteId = data['siteId'] as String?;

    if (siteId != null && siteId.isNotEmpty) {
      _afterFrame(() {
        AppNavigation.navigateToHomeMapFocus(
          args: MapSiteFocusRouteArgs(siteId: siteId),
        );
      });
      NotificationOpenDiagnostics.recordOpenSuccess(
        channel == _NotificationOpenChannel.remoteMessage
            ? 'push_site_map_focus'
            : 'data_site_map_focus',
      );
      return;
    }

    switch (type) {
      case 'REPORT_STATUS':
      case 'SITE_UPDATE':
      case 'UPVOTE':
      case 'COMMENT':
      case 'NEARBY_REPORT':
        _afterFrame(() => AppNavigation.navigateToHomeTab(0));
        NotificationOpenDiagnostics.recordOpenSuccess(
          channel == _NotificationOpenChannel.remoteMessage
              ? 'push_home'
              : 'data_home',
        );
        return;
      case 'CLEANUP_EVENT':
        final String? eventId = data['eventId'] as String?;
        if (eventId != null &&
            eventId.isNotEmpty &&
            notificationOpenPayloadLooksLikeEventId(eventId)) {
          _afterFrame(() {
            // ignore: discarded_futures, navigation runs post-frame, not awaited
            AppNavigation.pushEventDetail(eventId: eventId);
          });
          NotificationOpenDiagnostics.recordOpenSuccess(
            channel == _NotificationOpenChannel.remoteMessage
                ? 'push_event_detail'
                : 'data_event_detail',
          );
          return;
        }
        _afterFrame(AppNavigation.navigateToHomeEvents);
        NotificationOpenDiagnostics.recordOpenSuccess(
          channel == _NotificationOpenChannel.remoteMessage
              ? 'push_events'
              : 'data_events',
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
            cachedEventTitle: readEventsRepository()
                .findById(chatEventId)
                ?.title,
          );
          final EcoEvent? cachedEvent = readEventsRepository().findById(
            chatEventId,
          );
          final bool isOrganizer =
              cachedEvent != null &&
              cachedEvent.organizerId.isNotEmpty &&
              cachedEvent.organizerId == CurrentUser.id;
          _afterFrame(() {
            // ignore: discarded_futures, navigation runs post-frame, not awaited
            AppNavigation.pushEventChat(
              EventChatRouteArguments(
                eventId: chatEventId,
                eventTitle: eventTitle,
                isOrganizer: isOrganizer,
              ),
            );
          });
          NotificationOpenDiagnostics.recordOpenSuccess(
            channel == _NotificationOpenChannel.remoteMessage
                ? 'push_event_chat'
                : 'data_event_chat',
          );
          return;
        }
        _afterFrame(AppNavigation.navigateToHomeEvents);
        NotificationOpenDiagnostics.recordOpenSuccess(
          channel == _NotificationOpenChannel.remoteMessage
              ? 'push_events_fallback'
              : 'data_events_fallback',
        );
        return;
      default:
        _afterFrame(() => AppNavigation.navigateToHomeTab(0));
        NotificationOpenDiagnostics.recordOpenSuccess(
          channel == _NotificationOpenChannel.remoteMessage
              ? 'push_default'
              : 'data_home',
        );
    }
  }
}
