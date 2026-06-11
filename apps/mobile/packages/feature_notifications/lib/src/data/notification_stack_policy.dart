import 'package:feature_notifications/src/data/notification_navigation_origin.dart';
import 'package:feature_notifications/src/data/notification_navigation_target.dart';

/// Whether the executor should use deferred `go()` / tab navigation for [target].
///
/// Inbox opens preserve the notifications route; external push/deep-link taps may
/// reset shell location for tab-only targets (map focus, home tab, feature guide).
bool notificationUsesExternalGoNavigation({
  required NotificationNavigationOrigin origin,
  required NotificationNavigationTarget target,
}) {
  if (origin == NotificationNavigationOrigin.inbox) {
    return false;
  }
  return switch (target) {
    NotificationOpenHomeMapFocus() ||
    NotificationOpenHomeTab() ||
    NotificationOpenFeatureGuide() =>
      true,
    _ => false,
  };
}

/// Entity destinations always use root `push` regardless of entry source.
bool notificationUsesRootEntityPush(NotificationNavigationTarget target) {
  return switch (target) {
    NotificationOpenReportDetail() ||
    NotificationOpenSiteDetail() ||
    NotificationOpenEventDetail() ||
    NotificationOpenEventChat() ||
    NotificationOpenProfileAchievements() =>
      true,
    _ => false,
  };
}
