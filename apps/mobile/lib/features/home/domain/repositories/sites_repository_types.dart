import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';

/// Paginated sites list result.
class SitesListResult {
  const SitesListResult({
    required this.sites,
    required this.total,
    required this.page,
    required this.limit,
    this.nextCursor,
    this.servedFromCache = false,
    this.isStaleFallback = false,
    this.cachedAt,
    this.lastSuccessfulRefreshAt,
    this.feedVariant = 'v1',
  });

  final List<PollutionSite> sites;
  final int total;
  final int page;
  final int limit;
  final String? nextCursor;
  final bool servedFromCache;
  final bool isStaleFallback;
  final DateTime? cachedAt;
  final DateTime? lastSuccessfulRefreshAt;
  final String feedVariant;
}

class MapSitesResult {
  const MapSitesResult({
    required this.sites,
    this.servedFromCache = false,
    this.cachedAt,
    this.isStaleFallback = false,
    this.signedMediaExpiresAt,
  });

  final List<PollutionSite> sites;
  final bool servedFromCache;
  final DateTime? cachedAt;
  final bool isStaleFallback;

  /// When set (from GET /sites/map `meta`), map should refetch before this time for fresh presigned URLs.
  final DateTime? signedMediaExpiresAt;
}

class EngagementSnapshot {
  const EngagementSnapshot({
    required this.siteId,
    required this.upvotesCount,
    required this.commentsCount,
    required this.savesCount,
    required this.sharesCount,
    required this.isUpvotedByMe,
    required this.isSavedByMe,
  });

  final String siteId;
  final int upvotesCount;
  final int commentsCount;
  final int savesCount;
  final int sharesCount;
  final bool isUpvotedByMe;
  final bool isSavedByMe;
}

class SiteShareLinkPayload {
  const SiteShareLinkPayload({
    required this.siteId,
    required this.cid,
    required this.url,
    required this.token,
    required this.channel,
    required this.expiresAt,
  });

  final String siteId;
  final String cid;
  final String url;
  final String token;
  final String channel;
  final DateTime expiresAt;
}

class SiteCommentsResult {
  const SiteCommentsResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<SiteCommentItem> items;
  final int page;
  final int limit;
  final int total;
}

class SiteCommentItem {
  const SiteCommentItem({
    required this.id,
    this.parentId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.body,
    required this.createdAt,
    this.likeCount = 0,
    this.isLikedByMe = false,
    this.replies = const <SiteCommentItem>[],
    this.repliesCount = 0,
  });

  final String id;
  final String? parentId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String body;
  final DateTime createdAt;
  final int likeCount;
  final bool isLikedByMe;
  final List<SiteCommentItem> replies;
  final int repliesCount;
}

class SiteCommentLikeSnapshot {
  const SiteCommentLikeSnapshot({
    required this.commentId,
    required this.likesCount,
    required this.isLikedByMe,
  });

  final String commentId;
  final int likesCount;
  final bool isLikedByMe;
}

class SiteMediaResult {
  const SiteMediaResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<SiteMediaItem> items;
  final int page;
  final int limit;
  final int total;
}

class SiteMediaItem {
  const SiteMediaItem({
    required this.id,
    required this.reportId,
    required this.url,
    required this.createdAt,
  });

  final String id;
  final String reportId;
  final String url;
  final DateTime createdAt;
}

class SiteUpvotesResult {
  const SiteUpvotesResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  final List<SiteUpvoterItem> items;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;
}

class SiteUpvoterItem {
  const SiteUpvoterItem({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.upvotedAt,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final DateTime upvotedAt;
}
