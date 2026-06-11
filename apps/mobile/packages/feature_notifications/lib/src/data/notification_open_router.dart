import 'dart:async';

import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:feature_notifications/src/application/notifications_providers.dart';
import 'package:feature_notifications/src/data/notification_navigation_origin.dart';
import 'package:feature_notifications/src/data/notification_navigation_executor.dart';
import 'package:feature_notifications/src/data/notification_navigation_target.dart';
import 'package:feature_notifications/src/data/notification_open_diagnostics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

enum _NotificationOpenChannel { remoteMessage, dataPayload }

class NotificationOpenRouter {
  const NotificationOpenRouter._();

  static void _afterFrame(Future<void> Function() action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(action());
    });
  }

  static void handleOpen(BuildContext context, RemoteMessage message) {
    NotificationOpenDiagnostics.recordOpenAttempt('push_remote');
    _routeFromPayload(
      message.data,
      channel: _NotificationOpenChannel.remoteMessage,
      notificationTitle: message.notification?.title,
      context: context,
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
      context: context,
    );
  }

  static void _routeFromPayload(
    Map<String, dynamic> data, {
    required _NotificationOpenChannel channel,
    String? notificationTitle,
    BuildContext? context,
  }) {
    _recordOpenedIfNeeded(data);

    final NotificationNavigationTarget target =
        resolveNotificationNavigationTargetFromData(
          data,
          notificationTitle: notificationTitle,
        );

    final String prefix = channel == _NotificationOpenChannel.remoteMessage
        ? 'push'
        : 'data';

    _afterFrame(() async {
      await NotificationNavigationExecutor.execute(
        context: context,
        target: target,
        diagnosticsPrefix: prefix,
        origin: NotificationNavigationOrigin.external,
      );
    });
  }

  static void _recordOpenedIfNeeded(Map<String, dynamic> data) {
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
  }
}
