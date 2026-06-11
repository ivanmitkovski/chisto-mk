import 'package:feature_notifications/src/data/notification_open_payload.dart';
import 'package:feature_notifications/src/domain/models/notification_inbox_highlight.dart';
import 'package:feature_notifications/src/domain/models/user_notification.dart';

/// Resolved in-app destination for a notification tap (push or inbox).
sealed class NotificationNavigationTarget {
  const NotificationNavigationTarget();
}

final class NotificationOpenReportDetail extends NotificationNavigationTarget {
  const NotificationOpenReportDetail({required this.reportId});

  final String reportId;
}

final class NotificationOpenSiteDetail extends NotificationNavigationTarget {
  const NotificationOpenSiteDetail({
    required this.siteId,
    this.initialAction,
    this.initialHighlight,
    this.initialTabIndex = 0,
  });

  final String siteId;
  final String? initialAction;
  final NotificationInboxHighlight? initialHighlight;
  final int initialTabIndex;
}

final class NotificationOpenEventDetail extends NotificationNavigationTarget {
  const NotificationOpenEventDetail({required this.eventId});

  final String eventId;
}

final class NotificationOpenEventChat extends NotificationNavigationTarget {
  const NotificationOpenEventChat({
    required this.eventId,
    this.notificationTitle,
  });

  final String eventId;
  final String? notificationTitle;
}

/// Used by map deep links; the notification resolver does not produce this target.
final class NotificationOpenHomeMapFocus extends NotificationNavigationTarget {
  const NotificationOpenHomeMapFocus({required this.siteId});

  final String siteId;
}

/// Used by shell navigation; the notification resolver does not produce this target.
final class NotificationOpenHomeTab extends NotificationNavigationTarget {
  const NotificationOpenHomeTab({this.tabIndex = 0});

  final int tabIndex;
}

final class NotificationOpenFeatureGuide extends NotificationNavigationTarget {
  const NotificationOpenFeatureGuide();
}

final class NotificationOpenProfileAchievements
    extends NotificationNavigationTarget {
  const NotificationOpenProfileAchievements();
}

enum NotificationOpenFailureReason {
  missingReportId,
  missingSiteId,
  missingEventId,
  invalidEventId,
  unsupportedType,
}

final class NotificationOpenFailure extends NotificationNavigationTarget {
  const NotificationOpenFailure(this.reason);

  final NotificationOpenFailureReason reason;
}

String? _trimId(Object? raw) {
  if (raw is! String) return null;
  final String trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}

bool _isSiteDetailType(String? type) {
  switch (type) {
    case 'UPVOTE':
    case 'COMMENT':
    case 'SITE_UPDATE':
    case 'REPORT_STATUS':
    case 'NEARBY_REPORT':
      return true;
    default:
      return false;
  }
}

NotificationNavigationTarget resolveNotificationNavigationTarget({
  required String? type,
  required Map<String, dynamic>? data,
  String? notificationTitle,
}) {
  final String? dataKind = _trimId(data?['kind']);
  final String? reportId = _trimId(data?['reportId']);
  final String? siteId = _trimId(data?['siteId']);
  final String? eventId = _trimId(data?['eventId']);

  if (reportId != null && (type == 'REPORT_STATUS' || type == 'SYSTEM')) {
    return NotificationOpenReportDetail(reportId: reportId);
  }

  if (type == 'EVENT_CHAT') {
    if (eventId == null || eventId.isEmpty) {
      return const NotificationOpenFailure(
        NotificationOpenFailureReason.missingEventId,
      );
    }
    if (notificationOpenPayloadLooksLikeEventId(eventId)) {
      return NotificationOpenEventChat(
        eventId: eventId,
        notificationTitle: notificationTitle,
      );
    }
    return const NotificationOpenFailure(
      NotificationOpenFailureReason.invalidEventId,
    );
  }

  if (type == 'CLEANUP_EVENT') {
    if (eventId == null || eventId.isEmpty) {
      return const NotificationOpenFailure(
        NotificationOpenFailureReason.missingEventId,
      );
    }
    if (notificationOpenPayloadLooksLikeEventId(eventId)) {
      return NotificationOpenEventDetail(eventId: eventId);
    }
    return const NotificationOpenFailure(
      NotificationOpenFailureReason.invalidEventId,
    );
  }

  if (siteId != null && _isSiteDetailType(type)) {
    return NotificationOpenSiteDetail(
      siteId: siteId,
      initialAction: _trimId(data?['targetAction']),
      initialHighlight: _highlightFromData(data, type),
      initialTabIndex: int.tryParse(_trimId(data?['targetTab']) ?? '') ?? 0,
    );
  }

  if (type == 'SYSTEM' &&
      dataKind == 'report_received' &&
      siteId != null &&
      reportId == null) {
    return NotificationOpenSiteDetail(siteId: siteId);
  }

  if (type == 'ACHIEVEMENT') {
    return const NotificationOpenProfileAchievements();
  }

  if (type == 'WELCOME') {
    return const NotificationOpenFeatureGuide();
  }

  if (_isSiteDetailType(type)) {
    return const NotificationOpenFailure(
      NotificationOpenFailureReason.missingSiteId,
    );
  }

  return const NotificationOpenFailure(
    NotificationOpenFailureReason.unsupportedType,
  );
}

NotificationInboxHighlight? _highlightFromData(
  Map<String, dynamic>? data,
  String? type,
) {
  if (type != 'UPVOTE' && type != 'COMMENT') {
    return null;
  }
  final NotificationInboxHighlight highlight = NotificationInboxHighlight(
    commentId: _trimId(data?['commentId']),
    actorUserId: _trimId(data?['actorUserId']),
  );
  return highlight.hasTarget ? highlight : null;
}

NotificationNavigationTarget resolveNotificationNavigationTargetFromItem(
  UserNotification item, {
  String? notificationTitle,
}) {
  return resolveNotificationNavigationTarget(
    type: toNotificationTypeApiValue(item.type),
    data: item.data,
    notificationTitle: notificationTitle,
  );
}

NotificationNavigationTarget resolveNotificationNavigationTargetFromData(
  Map<String, dynamic> data, {
  String? notificationTitle,
}) {
  return resolveNotificationNavigationTarget(
    type: data['type'] as String? ?? data['notificationType'] as String?,
    data: data,
    notificationTitle: notificationTitle,
  );
}
