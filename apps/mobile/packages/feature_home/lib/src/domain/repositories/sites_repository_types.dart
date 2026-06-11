import 'package:feature_home/src/domain/models/pollution_site.dart';

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

  factory SitesListResult.empty({
    required int page,
    required int limit,
    String feedVariant = 'v1',
  }) {
    return SitesListResult(
      sites: const <PollutionSite>[],
      total: 0,
      page: page,
      limit: limit,
      nextCursor: null,
      servedFromCache: false,
      isStaleFallback: false,
      feedVariant: feedVariant,
    );
  }

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
    this.engagementTotal,
  });

  final List<SiteCommentItem> items;
  final int page;
  final int limit;
  final int total;
  /// Viewer-visible comment total (roots + replies), from API meta.engagementTotal.
  final int? engagementTotal;
}

class SiteCommentItem {
  const SiteCommentItem({
    required this.id,
    this.parentId,
    required this.authorId,
    required this.authorName,
    this.authorIsDeleted = false,
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
  final bool authorIsDeleted;
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

class SiteCoReportersResult {
  const SiteCoReportersResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  final List<SiteCoReporterItem> items;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;
}

class SiteCoReporterItem {
  const SiteCoReporterItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    this.isDeleted = false,
    this.avatarUrl,
    required this.reportedAt,
    required this.isOriginalReporter,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String displayName;
  final bool isDeleted;
  final String? avatarUrl;
  final DateTime reportedAt;
  final bool isOriginalReporter;
}

/// Filter dimensions sent with `POST /sites/search` (map chip parity).
class SiteMapSearchFilterContext {
  const SiteMapSearchFilterContext({
    required this.statuses,
    required this.pollutionTypes,
    required this.includeArchived,
  });

  final List<String> statuses;
  final List<String> pollutionTypes;
  final bool includeArchived;
}

class SiteMapSearchGeoIntent {
  const SiteMapSearchGeoIntent({
    required this.label,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  final String label;
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;
}

class SiteMapSearchRequest {
  const SiteMapSearchRequest({
    required this.query,
    this.limit = 24,
    this.lat,
    this.lng,
    this.statuses,
    this.pollutionTypes,
    this.includeArchived,
  });

  /// Prisma [SiteStatus] values only. Map UI adds `ARCHIVED` / `UNKNOWN` chips
  /// which are not enum members — they must not be sent on `POST /sites/search`
  /// or Nest validation rejects the whole body (`@IsEnum(SiteStatus, { each: true })`).
  static const Set<String> _apiWorkflowStatuses = <String>{
    'REPORTED',
    'VERIFIED',
    'CLEANUP_SCHEDULED',
    'IN_PROGRESS',
    'CLEANED',
    'DISPUTED',
  };

  final String query;
  final int limit;
  final double? lat;
  final double? lng;
  final List<String>? statuses;
  final List<String>? pollutionTypes;
  final bool? includeArchived;

  Map<String, dynamic> toBodyJson() {
    final List<String>? st = statuses;
    final List<String>? apiStatuses = st
        ?.where(_apiWorkflowStatuses.contains)
        .toList();
    final List<String>? pt = pollutionTypes;
    return <String, dynamic>{
      'query': query,
      'limit': limit,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (apiStatuses != null && apiStatuses.isNotEmpty)
        'statuses': apiStatuses,
      if (pt != null && pt.isNotEmpty) 'pollutionTypes': pt,
      if (includeArchived != null) 'includeArchived': includeArchived,
    };
  }
}

class SiteMapSearchResponse {
  const SiteMapSearchResponse({
    required this.items,
    this.suggestions = const <String>[],
    this.geoIntent,
  });

  final List<PollutionSite> items;
  final List<String> suggestions;
  final SiteMapSearchGeoIntent? geoIntent;
}
