import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/notifications/domain/models/notification_inbox_highlight.dart';

/// [GoRouter] `extra` for `/feed/:siteId` opened from the notifications inbox.
class FeedSiteDetailRouteExtra {
  const FeedSiteDetailRouteExtra({
    this.previewSite,
    this.initialAction,
    this.initialHighlight,
  });

  final PollutionSite? previewSite;
  final String? initialAction;
  final NotificationInboxHighlight? initialHighlight;
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
