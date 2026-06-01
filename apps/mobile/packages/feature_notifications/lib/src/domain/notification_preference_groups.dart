import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_notifications/src/domain/models/user_notification.dart';

/// User-facing preference row in the notifications settings sheet (may map to
/// multiple [UserNotificationType] values on the server).
enum NotificationPreferenceGroupId {
  siteUpdates,
  reportStatus,
  upvotes,
  comments,
  nearbyReports,
  cleanupEvents,
  eventChat,
  system,
}

/// One row in the notification preferences sheet.
class NotificationPreferenceGroup {
  const NotificationPreferenceGroup({
    required this.id,
    required this.types,
    this.showGroupedSubtitle = false,
  });

  final NotificationPreferenceGroupId id;
  final List<UserNotificationType> types;

  /// When true, show [AppLocalizations.notificationsPrefSystemGroupSubtitle]
  /// under the title (system group only).
  final bool showGroupedSubtitle;
}

/// Stable UI order for the preferences bottom sheet (8 rows).
const List<NotificationPreferenceGroup> kNotificationPreferenceGroups =
    <NotificationPreferenceGroup>[
      NotificationPreferenceGroup(
        id: NotificationPreferenceGroupId.siteUpdates,
        types: <UserNotificationType>[UserNotificationType.siteUpdate],
      ),
      NotificationPreferenceGroup(
        id: NotificationPreferenceGroupId.reportStatus,
        types: <UserNotificationType>[UserNotificationType.reportStatus],
      ),
      NotificationPreferenceGroup(
        id: NotificationPreferenceGroupId.upvotes,
        types: <UserNotificationType>[UserNotificationType.upvote],
      ),
      NotificationPreferenceGroup(
        id: NotificationPreferenceGroupId.comments,
        types: <UserNotificationType>[UserNotificationType.comment],
      ),
      NotificationPreferenceGroup(
        id: NotificationPreferenceGroupId.nearbyReports,
        types: <UserNotificationType>[UserNotificationType.nearbyReport],
      ),
      NotificationPreferenceGroup(
        id: NotificationPreferenceGroupId.cleanupEvents,
        types: <UserNotificationType>[UserNotificationType.cleanupEvent],
      ),
      NotificationPreferenceGroup(
        id: NotificationPreferenceGroupId.eventChat,
        types: <UserNotificationType>[UserNotificationType.eventChat],
      ),
      NotificationPreferenceGroup(
        id: NotificationPreferenceGroupId.system,
        types: <UserNotificationType>[
          UserNotificationType.system,
          UserNotificationType.achievement,
          UserNotificationType.welcome,
        ],
        showGroupedSubtitle: true,
      ),
    ];

/// Index of API preferences by type (last wins if duplicates exist).
Map<UserNotificationType, NotificationPreference> preferenceMapFromList(
  List<NotificationPreference> prefs,
) {
  final Map<UserNotificationType, NotificationPreference> map =
      <UserNotificationType, NotificationPreference>{};
  for (final NotificationPreference p in prefs) {
    map[p.type] = p;
  }
  return map;
}

NotificationPreference preferenceForType(
  Map<UserNotificationType, NotificationPreference> byType,
  UserNotificationType type,
) {
  return byType[type] ?? NotificationPreference(type: type, muted: false);
}

/// True when push/in-app delivery is paused (muted indefinitely or snoozed).
bool isPreferenceEffectivelyMuted(NotificationPreference pref) {
  if (!pref.muted) return false;
  if (pref.mutedUntil == null) return true;
  return pref.mutedUntil!.isAfter(DateTime.now());
}

/// Switch on when at least one type in the group can receive notifications.
bool isNotificationPreferenceGroupEnabled(
  NotificationPreferenceGroup group,
  Map<UserNotificationType, NotificationPreference> byType,
) {
  return group.types.any(
    (UserNotificationType t) =>
        !isPreferenceEffectivelyMuted(preferenceForType(byType, t)),
  );
}

String notificationPreferenceGroupTitle(
  AppLocalizations l10n,
  NotificationPreferenceGroupId id,
) {
  switch (id) {
    case NotificationPreferenceGroupId.siteUpdates:
      return l10n.notificationsTypeSiteUpdates;
    case NotificationPreferenceGroupId.reportStatus:
      return l10n.notificationsTypeReportStatus;
    case NotificationPreferenceGroupId.upvotes:
      return l10n.notificationsTypeUpvotes;
    case NotificationPreferenceGroupId.comments:
      return l10n.notificationsTypeComments;
    case NotificationPreferenceGroupId.nearbyReports:
      return l10n.notificationsTypeNearbyReports;
    case NotificationPreferenceGroupId.cleanupEvents:
      return l10n.notificationsTypeCleanupEvents;
    case NotificationPreferenceGroupId.eventChat:
      return l10n.notificationsTypeEventChat;
    case NotificationPreferenceGroupId.system:
      return l10n.notificationsTypeSystem;
  }
}

/// Subtitle under a preference row (enabled / snoozed / muted).
String notificationPreferenceGroupSubtitle(
  AppLocalizations l10n,
  NotificationPreferenceGroup group,
  Map<UserNotificationType, NotificationPreference> byType,
) {
  if (group.showGroupedSubtitle &&
      group.types.every(
        (UserNotificationType t) =>
            !isPreferenceEffectivelyMuted(preferenceForType(byType, t)),
      )) {
    return l10n.notificationsPrefSystemGroupSubtitle;
  }

  final List<NotificationPreference> prefs = group.types
      .map((UserNotificationType t) => preferenceForType(byType, t))
      .toList();

  if (prefs.every(
    (NotificationPreference p) => !isPreferenceEffectivelyMuted(p),
  )) {
    return l10n.notificationsPrefEnabled;
  }

  final List<NotificationPreference> snoozed = prefs
      .where(
        (NotificationPreference p) =>
            p.muted &&
            p.mutedUntil != null &&
            p.mutedUntil!.isAfter(DateTime.now()),
      )
      .toList();
  if (snoozed.length == prefs.length && snoozed.isNotEmpty) {
    final DateTime? latest = snoozed
        .map((NotificationPreference p) => p.mutedUntil)
        .whereType<DateTime>()
        .fold<DateTime?>(
          null,
          (DateTime? a, DateTime b) => a == null || b.isAfter(a) ? b : a,
        );
    if (latest != null) {
      final String time =
          '${latest.hour.toString().padLeft(2, '0')}:${latest.minute.toString().padLeft(2, '0')}';
      return l10n.notificationsPrefSnoozedUntil(time);
    }
  }

  if (prefs.any(isPreferenceEffectivelyMuted)) {
    return l10n.notificationsPrefMuted;
  }

  return l10n.notificationsPrefEnabled;
}

/// Applies [muted] / [mutedUntil] to every type in [group] (optimistic map update).
Map<UserNotificationType, NotificationPreference> applyGroupMuteToMap(
  Map<UserNotificationType, NotificationPreference> byType,
  NotificationPreferenceGroup group, {
  required bool muted,
  DateTime? mutedUntil,
}) {
  final Map<UserNotificationType, NotificationPreference> next =
      Map<UserNotificationType, NotificationPreference>.from(byType);
  for (final UserNotificationType type in group.types) {
    final NotificationPreference current = preferenceForType(next, type);
    next[type] = current.copyWith(
      muted: muted,
      mutedUntil: muted ? mutedUntil : null,
    );
  }
  return next;
}
