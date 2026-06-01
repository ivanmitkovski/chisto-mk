import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_notifications/feature_notifications.dart';

/// [GoRouter] `extra` for `/feed/:siteId` opened from the notifications inbox.
class FeedSiteDetailRouteExtra {
  const FeedSiteDetailRouteExtra({
    this.previewSite,
    this.initialAction,
    this.initialHighlight,
    this.initialTabIndex = 0,
  });

  final PollutionSite? previewSite;
  final String? initialAction;
  final NotificationInboxHighlight? initialHighlight;

  /// 0 = pollution site, 1 = cleaning events, 2 = history.
  final int initialTabIndex;
}

/// [GoRouter] `extra` for `/feed/:siteId/upvoters`.
class FeedSiteUpvotersRouteExtra {
  const FeedSiteUpvotersRouteExtra({this.highlightUserId});

  final String? highlightUserId;
}

/// [GoRouter] `extra` for `/feed/:siteId/comments`.
class FeedSiteCommentsRouteExtra {
  const FeedSiteCommentsRouteExtra({
    this.highlightCommentId,
    this.highlightActorUserId,
  });

  final String? highlightCommentId;
  final String? highlightActorUserId;
}
