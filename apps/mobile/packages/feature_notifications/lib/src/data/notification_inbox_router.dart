import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:chisto_infrastructure/shared/current_user.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:feature_events/feature_events.dart';
import 'package:feature_home/feature_home.dart';
import 'package:feature_notifications/src/data/notification_inbox_actions.dart';
import 'package:feature_notifications/src/data/notification_open_diagnostics.dart';
import 'package:feature_notifications/src/data/notification_open_payload.dart';
import 'package:feature_notifications/src/domain/models/notification_inbox_highlight.dart';
import 'package:feature_notifications/src/domain/models/user_notification.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

/// Routes inbox notification taps to the correct in-app destination.
class NotificationInboxRouter {
  const NotificationInboxRouter._();

  static Future<bool> open(
    BuildContext context,
    UserNotification item, {
    List<PollutionSite> availableSites = const <PollutionSite>[],
  }) async {
    switch (item.type) {
      case UserNotificationType.upvote:
      case UserNotificationType.comment:
      case UserNotificationType.siteUpdate:
      case UserNotificationType.reportStatus:
      case UserNotificationType.nearbyReport:
        return _openSiteDetail(context, item, availableSites: availableSites);
      case UserNotificationType.cleanupEvent:
        return _openEventDetail(context, item);
      case UserNotificationType.eventChat:
        return _openEventChat(context, item);
      case UserNotificationType.system:
        if (item.dataKind == 'report_received' && item.targetSiteId != null) {
          return _openSiteDetail(context, item, availableSites: availableSites);
        }
        NotificationOpenDiagnostics.recordOpenFailure(
          _diagLabel(item, 'no_action'),
        );
        return false;
      case UserNotificationType.achievement:
      case UserNotificationType.welcome:
        NotificationOpenDiagnostics.recordOpenFailure(
          _diagLabel(item, 'no_action'),
        );
        return false;
    }
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

  static Future<bool> _openSiteDetail(
    BuildContext context,
    UserNotification item, {
    required List<PollutionSite> availableSites,
  }) async {
    final String? siteId = item.targetSiteId?.trim();
    if (siteId == null || siteId.isEmpty) {
      NotificationOpenDiagnostics.recordOpenFailure(
        _diagLabel(item, 'missing_site_id'),
      );
      return false;
    }

    PollutionSite? site = _findSiteById(availableSites, siteId);
    if (site == null) {
      try {
        site = await readRoot(sitesRepositoryProvider).getSiteById(siteId);
      } on Object catch (e, st) {
        AppLog.warn(
          'notification_inbox: site fetch failed siteId=$siteId',
          error: e,
          stackTrace: st,
        );
        site = null;
      }
    }

    if (site == null) {
      NotificationOpenDiagnostics.recordOpenFailure(
        _diagLabel(item, 'site_missing'),
      );
      if (context.mounted) {
        AppSnack.show(
          context,
          message: context.l10n.notificationsSiteUnavailable,
          type: AppSnackType.warning,
        );
      }
      return false;
    }

    if (!context.mounted) return false;

    final String? action = resolveInitialAction(item);
    final NotificationInboxHighlight? highlight = resolveHighlight(item);
    final GoRouter? router = GoRouter.maybeOf(context);

    if (router != null) {
      Navigator.of(context).pop();
      await router.push(
        '/feed/$siteId',
        extra: FeedSiteDetailRouteExtra(
          previewSite: site,
          initialAction: action,
          initialHighlight: highlight,
        ),
      );
      NotificationOpenDiagnostics.recordOpenSuccess(
        _diagLabel(item, 'feed_shell_site_detail'),
      );
      return true;
    }

    final int tabIndex = int.tryParse(item.targetTab ?? '') ?? 0;
    await Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => PollutionSiteDetailScreen(
          site: site!,
          initialTabIndex: tabIndex,
          initialAction: action,
          initialHighlight: highlight,
        ),
      ),
    );
    NotificationOpenDiagnostics.recordOpenSuccess(
      _diagLabel(item, 'site_detail'),
    );
    return true;
  }

  static Future<bool> _openEventDetail(
    BuildContext context,
    UserNotification item,
  ) async {
    final String? eventId = item.targetEventId?.trim();
    if (eventId == null ||
        eventId.isEmpty ||
        !notificationOpenPayloadLooksLikeEventId(eventId)) {
      NotificationOpenDiagnostics.recordOpenFailure(
        _diagLabel(item, 'missing_event_id'),
      );
      if (context.mounted) {
        AppSnack.show(
          context,
          message: context.l10n.eventsEventNotFoundShort,
          type: AppSnackType.warning,
        );
      }
      return false;
    }

    if (!context.mounted) return false;
    final GoRouter? router = GoRouter.maybeOf(context);
    if (router != null) {
      Navigator.of(context).pop();
      final BuildContext? shellContext =
          router.routerDelegate.navigatorKey.currentContext;
      if (shellContext != null) {
        await EventsNavigation.openDetail(shellContext, eventId: eventId);
      }
    } else {
      await EventsNavigation.openDetail(context, eventId: eventId);
    }
    NotificationOpenDiagnostics.recordOpenSuccess(
      _diagLabel(item, 'event_detail'),
    );
    return true;
  }

  static Future<bool> _openEventChat(
    BuildContext context,
    UserNotification item,
  ) async {
    final String? eventId = item.targetEventId?.trim();
    if (eventId == null ||
        eventId.isEmpty ||
        !notificationOpenPayloadLooksLikeEventId(eventId)) {
      NotificationOpenDiagnostics.recordOpenFailure(
        _diagLabel(item, 'missing_event_id'),
      );
      if (context.mounted) {
        AppSnack.show(
          context,
          message: context.l10n.eventsEventNotFoundShort,
          type: AppSnackType.warning,
        );
      }
      return false;
    }

    final EcoEvent? cachedEvent = readEventsRepository().findById(eventId);
    final String eventTitle = _resolveChatTitle(item, cachedEvent?.title);
    final bool isOrganizer =
        cachedEvent != null &&
        cachedEvent.organizerId.isNotEmpty &&
        cachedEvent.organizerId == CurrentUser.id;

    if (!context.mounted) return false;
    final GoRouter? router = GoRouter.maybeOf(context);
    if (router != null) {
      Navigator.of(context).pop();
    }
    final BuildContext navContext = router != null
        ? (router.routerDelegate.navigatorKey.currentContext ?? context)
        : context;
    if (!navContext.mounted) return false;
    await AppNavigation.pushEventChat(
      EventChatRouteArguments(
        eventId: eventId,
        eventTitle: eventTitle,
        isOrganizer: isOrganizer,
      ),
    );
    NotificationOpenDiagnostics.recordOpenSuccess(
      _diagLabel(item, 'event_chat'),
    );
    return true;
  }

  static String _resolveChatTitle(UserNotification item, String? cachedTitle) {
    final String fromData = item.eventTitleFromData?.trim() ?? '';
    if (fromData.isNotEmpty) return fromData;
    final String fromCache = cachedTitle?.trim() ?? '';
    if (fromCache.isNotEmpty) return fromCache;
    return item.title.trim();
  }

  static PollutionSite? _findSiteById(List<PollutionSite> sites, String id) {
    for (final PollutionSite site in sites) {
      if (site.id == id) return site;
    }
    return null;
  }

  static String _diagLabel(UserNotification item, String outcome) {
    return 'list_tap:${toNotificationTypeApiValue(item.type)}:$outcome';
  }
}
