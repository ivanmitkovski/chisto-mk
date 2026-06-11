import 'package:feature_home/feature_home.dart';
import 'package:feature_notifications/src/data/notification_navigation_origin.dart';
import 'package:feature_notifications/src/data/notification_navigation_executor.dart';
import 'package:feature_notifications/src/data/notification_navigation_target.dart';
import 'package:feature_notifications/src/data/notification_inbox_actions.dart';
import 'package:feature_notifications/src/domain/models/notification_inbox_highlight.dart';
import 'package:feature_notifications/src/domain/models/user_notification.dart';
import 'package:flutter/material.dart';

/// Routes inbox notification taps to the correct in-app destination.
class NotificationInboxRouter {
  const NotificationInboxRouter._();

  static Future<bool> open(
    BuildContext context,
    UserNotification item, {
    List<PollutionSite> availableSites = const <PollutionSite>[],
  }) async {
    final NotificationNavigationTarget target =
        resolveNotificationNavigationTargetFromItem(item);
    return NotificationNavigationExecutor.execute(
      context: context,
      target: target,
      availableSites: availableSites,
      sourceItem: item,
      diagnosticsPrefix: 'list_tap:${toNotificationTypeApiValue(item.type)}',
      origin: NotificationNavigationOrigin.inbox,
    );
  }

  static NotificationInboxHighlight? resolveHighlight(UserNotification item) {
    switch (item.type) {
      case UserNotificationType.upvote:
      case UserNotificationType.comment:
        final NotificationInboxHighlight highlight = NotificationInboxHighlight(
          commentId: item.highlightCommentId?.trim(),
          actorUserId: item.highlightActorUserId?.trim(),
        );
        return highlight.hasTarget ? highlight : null;
      case UserNotificationType.siteUpdate:
      case UserNotificationType.reportStatus:
      case UserNotificationType.nearbyReport:
      case UserNotificationType.cleanupEvent:
      case UserNotificationType.eventChat:
      case UserNotificationType.system:
      case UserNotificationType.achievement:
      case UserNotificationType.welcome:
        return null;
    }
  }

  static String? resolveInitialAction(UserNotification item) {
    final String? action = item.targetAction?.trim();
    if (action == NotificationInboxActions.showComments ||
        action == NotificationInboxActions.showUpvoters) {
      return action;
    }
    switch (item.type) {
      case UserNotificationType.upvote:
        return NotificationInboxActions.showUpvoters;
      case UserNotificationType.comment:
        return NotificationInboxActions.showComments;
      case UserNotificationType.siteUpdate:
      case UserNotificationType.reportStatus:
      case UserNotificationType.nearbyReport:
      case UserNotificationType.cleanupEvent:
      case UserNotificationType.eventChat:
      case UserNotificationType.system:
      case UserNotificationType.achievement:
      case UserNotificationType.welcome:
        return null;
    }
  }
}
