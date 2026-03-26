import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';

/// Repository for sites API (pollution sites for map/feed).
abstract class SitesRepository {
  /// List sites with optional geo filter. When lat/lng provided, sorts by distance.
  Future<SitesListResult> getSites({
    double? latitude,
    double? longitude,
    double radiusKm = 10,
    String? status,
    int page = 1,
    int limit = 20,
    String sort = 'hybrid',
    String mode = 'for_you',
    bool explain = false,
    String? cursor,
  });

  /// Get single site by ID with reports and events.
  Future<PollutionSite?> getSiteById(String id);

  Future<EngagementSnapshot> upvoteSite(String id);
  Future<EngagementSnapshot> removeSiteUpvote(String id);
  Future<EngagementSnapshot> saveSite(String id);
  Future<EngagementSnapshot> unsaveSite(String id);
  Future<EngagementSnapshot> shareSite(String id, {String channel = 'native'});
  Future<SiteCommentsResult> getSiteComments(
    String id, {
    int page = 1,
    int limit = 20,
    String sort = 'top',
    String? parentId,
  });
  Future<SiteCommentItem> createSiteComment(String id, String body, {String? parentId});
  Future<void> updateSiteComment(String siteId, String commentId, String body);
  Future<void> deleteSiteComment(String siteId, String commentId);
  Future<SiteCommentLikeSnapshot> likeSiteComment(String siteId, String commentId);
  Future<SiteCommentLikeSnapshot> unlikeSiteComment(String siteId, String commentId);
  Future<SiteMediaResult> getSiteMedia(String id, {int page = 1, int limit = 24});
  Future<void> trackFeedEvent(
    String siteId, {
    required String eventType,
    String? sessionId,
    Map<String, dynamic>? metadata,
  });
  Future<void> submitFeedFeedback(
    String siteId, {
    required String feedbackType,
    String? sessionId,
    Map<String, dynamic>? metadata,
  });
}

/// Paginated sites list result.
class SitesListResult {
  const SitesListResult({
    required this.sites,
    required this.total,
    required this.page,
    required this.limit,
    this.nextCursor,
  });

  final List<PollutionSite> sites;
  final int total;
  final int page;
  final int limit;
  final String? nextCursor;
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
