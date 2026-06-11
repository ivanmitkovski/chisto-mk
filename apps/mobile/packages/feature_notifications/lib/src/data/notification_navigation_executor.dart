import 'dart:async';

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/navigation/app_go_router.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:chisto_infrastructure/core/providers/home_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:chisto_infrastructure/shared/current_user.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:feature_events/feature_events.dart';
import 'package:feature_home/feature_home.dart';
import 'package:feature_home/src/presentation/navigation/feed_shell_route_extras.dart';
import 'package:feature_notifications/src/data/event_chat_open_guard.dart';
import 'package:feature_notifications/src/data/notification_inbox_actions.dart';
import 'package:feature_notifications/src/data/notification_navigation_origin.dart';
import 'package:feature_notifications/src/data/notification_open_diagnostics.dart';
import 'package:feature_notifications/src/data/notification_navigation_target.dart';
import 'package:feature_notifications/src/data/notification_stack_policy.dart';
import 'package:feature_notifications/src/domain/models/notification_inbox_highlight.dart';
import 'package:feature_notifications/src/domain/models/user_notification.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Performs navigation for [NotificationNavigationTarget] (push + inbox).
class NotificationNavigationExecutor {
  const NotificationNavigationExecutor._();

  static BuildContext? _resolveContext(BuildContext? context) {
    if (context != null && context.mounted) {
      return context;
    }
    final BuildContext? root =
        appGoRouter.routerDelegate.navigatorKey.currentContext;
    if (root != null && root.mounted) {
      return root;
    }
    return null;
  }

  static GoRouter get _router => appGoRouter;

  static void _showSnack(
    BuildContext? context, {
    required String message,
  }) {
    final BuildContext? resolved = _resolveContext(context);
    if (resolved == null) {
      return;
    }
    AppSnack.show(
      resolved,
      message: message,
      type: AppSnackType.warning,
    );
  }

  static Future<bool> execute({
    BuildContext? context,
    required NotificationNavigationTarget target,
    List<PollutionSite> availableSites = const <PollutionSite>[],
    UserNotification? sourceItem,
    String? diagnosticsPrefix,
    NotificationNavigationOrigin origin = NotificationNavigationOrigin.external,
  }) async {
    final String prefix = diagnosticsPrefix ?? 'notification';
    switch (target) {
      case NotificationOpenReportDetail(:final String reportId):
        return _openReportDetail(
          context,
          reportId: reportId,
          diagnosticsPrefix: prefix,
        );
      case NotificationOpenSiteDetail(
        :final String siteId,
        :final String? initialAction,
        :final NotificationInboxHighlight? initialHighlight,
        :final int initialTabIndex,
      ):
        return _openSiteDetail(
          context,
          siteId: siteId,
          availableSites: availableSites,
          initialAction: _normalizeInitialAction(initialAction, sourceItem),
          initialHighlight:
              initialHighlight ??
              (sourceItem != null ? _highlightFromItem(sourceItem) : null),
          initialTabIndex: initialTabIndex,
          diagnosticsPrefix: prefix,
        );
      case NotificationOpenEventDetail(:final String eventId):
        return _openEventDetail(context, eventId: eventId, prefix: prefix);
      case NotificationOpenEventChat(
        :final String eventId,
        :final String? notificationTitle,
      ):
        return _openEventChat(
          context,
          eventId: eventId,
          notificationTitle: notificationTitle,
          sourceItem: sourceItem,
          prefix: prefix,
        );
      case NotificationOpenHomeMapFocus(:final String siteId):
        if (!notificationUsesExternalGoNavigation(
          origin: origin,
          target: target,
        )) {
          readRoot(homeShellControllerProvider.notifier).applyInitialFocus(
            mapSiteIdToFocus: siteId,
          );
          NotificationOpenDiagnostics.recordOpenSuccess('${prefix}_map_focus');
          return true;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppNavigation.navigateToHomeMapFocus(
            args: MapSiteFocusRouteArgs(siteId: siteId),
          );
        });
        NotificationOpenDiagnostics.recordOpenSuccess('${prefix}_map_focus');
        return true;
      case NotificationOpenHomeTab(:final int tabIndex):
        if (!notificationUsesExternalGoNavigation(
          origin: origin,
          target: target,
        )) {
          NotificationOpenDiagnostics.recordOpenSuccess('${prefix}_home_tab');
          return true;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppNavigation.navigateToHomeTab(tabIndex);
        });
        NotificationOpenDiagnostics.recordOpenSuccess('${prefix}_home_tab');
        return true;
      case NotificationOpenFeatureGuide():
        if (!notificationUsesExternalGoNavigation(
          origin: origin,
          target: target,
        )) {
          readRoot(homeShellControllerProvider.notifier).applyInitialFocus(
            startCoachTour: true,
          );
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppNavigation.navigateToFeatureGuide();
          });
        }
        NotificationOpenDiagnostics.recordOpenSuccess('${prefix}_feature_guide');
        return true;
      case NotificationOpenProfileAchievements():
        return _openProfileAchievements(context, prefix: prefix);
      case NotificationOpenFailure(:final NotificationOpenFailureReason reason):
        NotificationOpenDiagnostics.recordOpenFailure('${prefix}_$reason');
        final BuildContext? resolved = _resolveContext(context);
        if (resolved != null) {
          AppSnack.show(
            resolved,
            message: _failureMessage(resolved, reason),
            type: AppSnackType.warning,
          );
        }
        return false;
    }
  }

  static String? _normalizeInitialAction(
    String? action,
    UserNotification? sourceItem,
  ) {
    if (action == NotificationInboxActions.showComments ||
        action == NotificationInboxActions.showUpvoters) {
      return action;
    }
    if (sourceItem == null) {
      return action;
    }
    switch (sourceItem.type) {
      case UserNotificationType.upvote:
        return NotificationInboxActions.showUpvoters;
      case UserNotificationType.comment:
        return NotificationInboxActions.showComments;
      default:
        return action;
    }
  }

  static NotificationInboxHighlight? _highlightFromItem(UserNotification item) {
    switch (item.type) {
      case UserNotificationType.upvote:
      case UserNotificationType.comment:
        final NotificationInboxHighlight highlight = NotificationInboxHighlight(
          commentId: item.highlightCommentId?.trim(),
          actorUserId: item.highlightActorUserId?.trim(),
        );
        return highlight.hasTarget ? highlight : null;
      default:
        return null;
    }
  }

  static Future<bool> _openReportDetail(
    BuildContext? context, {
    required String reportId,
    required String diagnosticsPrefix,
  }) async {
    final String trimmed = reportId.trim();
    if (trimmed.isEmpty) {
      NotificationOpenDiagnostics.recordOpenFailure(
        '${diagnosticsPrefix}_missing_report_id',
      );
      return false;
    }
    try {
      await AppNavigation.pushReportDetail(reportId: trimmed);
      NotificationOpenDiagnostics.recordOpenSuccess(
        '${diagnosticsPrefix}_report_detail',
      );
      return true;
    } on Object catch (e, st) {
      AppLog.warn('notification_nav: report push failed', error: e, stackTrace: st);
      NotificationOpenDiagnostics.recordOpenFailure(
        '${diagnosticsPrefix}_report_push_failed',
      );
      return false;
    }
  }

  static Future<bool> _openSiteDetail(
    BuildContext? context, {
    required String siteId,
    required List<PollutionSite> availableSites,
    String? initialAction,
    NotificationInboxHighlight? initialHighlight,
    int initialTabIndex = 0,
    required String diagnosticsPrefix,
  }) async {
    PollutionSite? site = _findSiteById(availableSites, siteId);
    if (site == null) {
      try {
        site = await readRoot(sitesRepositoryProvider).getSiteById(siteId);
      } on Object catch (e, st) {
        AppLog.warn(
          'notification_nav: site fetch failed siteId=$siteId',
          error: e,
          stackTrace: st,
        );
        site = null;
      }
    }

    if (site == null) {
      NotificationOpenDiagnostics.recordOpenFailure(
        '${diagnosticsPrefix}_site_missing',
      );
      _showSnack(
        context,
        message: _resolveContext(context)?.l10n.notificationsSiteUnavailable ??
            'Site unavailable',
      );
      return false;
    }

    final FeedSiteDetailRouteExtra extra = FeedSiteDetailRouteExtra(
      previewSite: site,
      initialAction: initialAction,
      initialHighlight: initialHighlight,
      initialTabIndex: initialTabIndex,
    );

    final BuildContext? resolved = _resolveContext(context);
    if (resolved != null) {
      final GoRouter? router = GoRouter.maybeOf(resolved);
      if (router != null) {
        await router.push('/feed/$siteId', extra: extra);
        NotificationOpenDiagnostics.recordOpenSuccess(
          '${diagnosticsPrefix}_feed_shell_site_detail',
        );
        return true;
      }

      await Navigator.of(resolved).push(
        CupertinoPageRoute<void>(
          builder: (_) => PollutionSiteDetailScreen(
            site: site!,
            initialTabIndex: initialTabIndex,
            initialAction: initialAction,
            initialHighlight: initialHighlight,
          ),
        ),
      );
      NotificationOpenDiagnostics.recordOpenSuccess(
        '${diagnosticsPrefix}_site_detail',
      );
      return true;
    }

    await _router.push('/feed/$siteId', extra: extra);
    NotificationOpenDiagnostics.recordOpenSuccess(
      '${diagnosticsPrefix}_feed_shell_site_detail',
    );
    return true;
  }

  static Future<bool> _openEventDetail(
    BuildContext? context, {
    required String eventId,
    required String prefix,
  }) async {
    try {
      await AppNavigation.pushEventDetail(eventId: eventId);
      NotificationOpenDiagnostics.recordOpenSuccess('${prefix}_event_detail');
      return true;
    } on Object catch (e, st) {
      AppLog.warn('notification_nav: event push failed', error: e, stackTrace: st);
      NotificationOpenDiagnostics.recordOpenFailure('${prefix}_event_missing');
      _showSnack(
        context,
        message:
            _resolveContext(context)?.l10n.notificationsSiteUnavailable ??
            'Event unavailable',
      );
      return false;
    }
  }

  static Future<bool> _openEventChat(
    BuildContext? context, {
    required String eventId,
    required String? notificationTitle,
    UserNotification? sourceItem,
    required String prefix,
  }) async {
    final EventsRepository eventsRepo = readEventsRepository();
    EcoEvent? cachedEvent = eventsRepo.findById(eventId);
    if (cachedEvent == null) {
      final bool available = await EventChatOpenGuard.isEventAvailableForChat(
        eventId,
      );
      if (!available) {
        NotificationOpenDiagnostics.recordOpenFailure('${prefix}_event_missing');
        _showSnack(
          context,
          message:
              _resolveContext(context)?.l10n.eventsEventNotFoundBody ??
              'Event not found',
        );
        return false;
      }
      cachedEvent = eventsRepo.findById(eventId);
    }

    final String eventTitle = _resolveChatTitle(
      sourceItem,
      notificationTitle,
      cachedEvent?.title,
    );
    final bool isOrganizer =
        cachedEvent != null &&
        cachedEvent.organizerId.isNotEmpty &&
        cachedEvent.organizerId == CurrentUser.id;

    await AppNavigation.pushEventChat(
      EventChatRouteArguments(
        eventId: eventId,
        eventTitle: eventTitle,
        isOrganizer: isOrganizer,
      ),
    );
    NotificationOpenDiagnostics.recordOpenSuccess('${prefix}_event_chat');
    return true;
  }

  static Future<bool> _openProfileAchievements(
    BuildContext? context, {
    required String prefix,
  }) async {
    final bool opened = await AppNavigation.pushProfilePointsHistory();
    if (!opened) {
      NotificationOpenDiagnostics.recordOpenFailure('${prefix}_profile_missing');
      _showSnack(
        context,
        message:
            _resolveContext(context)?.l10n.notificationsSiteUnavailable ??
            'Profile unavailable',
      );
      return false;
    }
    NotificationOpenDiagnostics.recordOpenSuccess('${prefix}_profile_points');
    return true;
  }

  static String _resolveChatTitle(
    UserNotification? item,
    String? notificationTitle,
    String? cachedTitle,
  ) {
    final String fromData = item?.eventTitleFromData?.trim() ?? '';
    if (fromData.isNotEmpty) return fromData;
    final String fromNotif = notificationTitle?.trim() ?? '';
    if (fromNotif.isNotEmpty) return fromNotif;
    final String fromCache = cachedTitle?.trim() ?? '';
    if (fromCache.isNotEmpty) return fromCache;
    return item?.title.trim() ?? '';
  }

  static PollutionSite? _findSiteById(List<PollutionSite> sites, String id) {
    for (final PollutionSite site in sites) {
      if (site.id == id) return site;
    }
    return null;
  }

  static String _failureMessage(
    BuildContext context,
    NotificationOpenFailureReason reason,
  ) {
    switch (reason) {
      case NotificationOpenFailureReason.missingSiteId:
      case NotificationOpenFailureReason.missingReportId:
      case NotificationOpenFailureReason.missingEventId:
      case NotificationOpenFailureReason.invalidEventId:
        return context.l10n.notificationsSiteUnavailable;
      case NotificationOpenFailureReason.unsupportedType:
        return context.l10n.notificationsSiteUnavailable;
    }
  }
}
