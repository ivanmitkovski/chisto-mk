import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/home/domain/repositories/site_comments_repository.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';

/// HTTP implementation of [SiteCommentsRepository] (comments, upvotes, media).
class ApiSiteCommentsRepository implements SiteCommentsRepository {
  ApiSiteCommentsRepository(this._client);

  final ApiClient _client;

  @override
  Future<SiteCommentsResult> getSiteComments(
    String id, {
    int page = 1,
    int limit = 20,
    String sort = 'top',
    String? parentId,
  }) async {
    final String query = <String>[
      'page=$page',
      'limit=$limit',
      'sort=$sort',
      if (parentId != null && parentId.isNotEmpty) 'parentId=$parentId',
    ].join('&');
    final ApiResponse response = await _client.get(
      '/sites/$id/comments?$query',
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    final List<dynamic> data = json['data'] as List<dynamic>? ?? <dynamic>[];
    final List<SiteCommentItem> items = data
        .whereType<Map<String, dynamic>>()
        .map<SiteCommentItem>(_siteCommentFromJson)
        .toList();
    final Map<String, dynamic>? meta = json['meta'] as Map<String, dynamic>?;
    return SiteCommentsResult(
      items: items,
      page: (meta?['page'] as num?)?.toInt() ?? page,
      limit: (meta?['limit'] as num?)?.toInt() ?? limit,
      total: (meta?['total'] as num?)?.toInt() ?? items.length,
    );
  }

  @override
  Future<SiteUpvotesResult> getSiteUpvotes(
    String id, {
    int page = 1,
    int limit = 20,
  }) async {
    final String query = 'page=$page&limit=$limit';
    final ApiResponse response = await _client.get('/sites/$id/upvotes?$query');
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    final List<dynamic> data = json['data'] as List<dynamic>? ?? <dynamic>[];
    final List<SiteUpvoterItem> items = data
        .whereType<Map<String, dynamic>>()
        .map<SiteUpvoterItem>(_siteUpvoterFromJson)
        .toList();
    final Map<String, dynamic>? meta = json['meta'] as Map<String, dynamic>?;
    return SiteUpvotesResult(
      items: items,
      page: (meta?['page'] as num?)?.toInt() ?? page,
      limit: (meta?['limit'] as num?)?.toInt() ?? limit,
      total: (meta?['total'] as num?)?.toInt() ?? items.length,
      hasMore: meta?['hasMore'] as bool? ?? false,
    );
  }

  @override
  Future<SiteCommentItem> createSiteComment(
    String id,
    String body, {
    String? parentId,
  }) async {
    final ApiResponse response = await _client.post(
      '/sites/$id/comments',
      body: <String, dynamic>{
        'body': body,
        if (parentId != null && parentId.isNotEmpty) 'parentId': parentId,
      },
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    return _siteCommentFromJson(json);
  }

  @override
  Future<void> updateSiteComment(
    String siteId,
    String commentId,
    String body,
  ) async {
    await _client.patch(
      '/sites/$siteId/comments/$commentId',
      body: <String, dynamic>{'body': body},
    );
  }

  @override
  Future<void> deleteSiteComment(String siteId, String commentId) async {
    await _client.delete('/sites/$siteId/comments/$commentId');
  }

  @override
  Future<SiteCommentLikeSnapshot> likeSiteComment(
    String siteId,
    String commentId,
  ) async {
    final ApiResponse response = await _client.post(
      '/sites/$siteId/comments/$commentId/like',
    );
    return _siteCommentLikeSnapshotFromJson(response.json);
  }

  @override
  Future<SiteCommentLikeSnapshot> unlikeSiteComment(
    String siteId,
    String commentId,
  ) async {
    final ApiResponse response = await _client.delete(
      '/sites/$siteId/comments/$commentId/like',
    );
    return _siteCommentLikeSnapshotFromJson(response.json);
  }

  @override
  Future<SiteMediaResult> getSiteMedia(
    String id, {
    int page = 1,
    int limit = 24,
  }) async {
    final ApiResponse response = await _client.get(
      '/sites/$id/media?page=$page&limit=$limit',
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    final List<dynamic> data = json['data'] as List<dynamic>? ?? <dynamic>[];
    final List<SiteMediaItem> items = data
        .whereType<Map<String, dynamic>>()
        .map<SiteMediaItem>(
          (Map<String, dynamic> item) => SiteMediaItem(
            id: item['id'] as String? ?? '',
            reportId: item['reportId'] as String? ?? '',
            url: item['url'] as String? ?? '',
            createdAt:
                DateTime.tryParse(item['createdAt'] as String? ?? '') ??
                DateTime.now(),
          ),
        )
        .toList();
    final Map<String, dynamic>? meta = json['meta'] as Map<String, dynamic>?;
    return SiteMediaResult(
      items: items,
      page: (meta?['page'] as num?)?.toInt() ?? page,
      limit: (meta?['limit'] as num?)?.toInt() ?? limit,
      total: (meta?['total'] as num?)?.toInt() ?? items.length,
    );
  }
}

SiteUpvoterItem _siteUpvoterFromJson(Map<String, dynamic> json) {
  final String userId = '${json['userId'] ?? json['user_id'] ?? ''}'.trim();
  final String displayName =
      '${json['displayName'] ?? json['display_name'] ?? ''}'.trim();
  final Object? av = json['avatarUrl'] ?? json['avatar_url'];
  final String? avatarUrl =
      av is String && av.trim().isNotEmpty ? av.trim() : null;
  final Object? rawAt = json['upvotedAt'] ?? json['upvoted_at'];
  final DateTime upvotedAt = rawAt is String && rawAt.isNotEmpty
      ? (DateTime.tryParse(rawAt) ?? DateTime.fromMillisecondsSinceEpoch(0))
      : DateTime.fromMillisecondsSinceEpoch(0);
  return SiteUpvoterItem(
    userId: userId.isEmpty ? 'user-${displayName.hashCode}' : userId,
    displayName: displayName.isEmpty ? 'Anonymous' : displayName,
    avatarUrl: avatarUrl,
    upvotedAt: upvotedAt,
  );
}

SiteCommentItem _siteCommentFromJson(Map<String, dynamic> item) {
  final List<dynamic> repliesJson =
      item['replies'] as List<dynamic>? ?? <dynamic>[];
  final Object? authorAvatarRaw = item['authorAvatarUrl'] ?? item['author_avatar_url'];
  final String? authorAvatarUrl = authorAvatarRaw is String && authorAvatarRaw.trim().isNotEmpty
      ? authorAvatarRaw.trim()
      : null;
  return SiteCommentItem(
    id: item['id'] as String? ?? '',
    parentId: item['parentId'] as String?,
    authorId: item['authorId'] as String? ?? '',
    authorName: item['authorName'] as String? ?? 'Anonymous',
    authorAvatarUrl: authorAvatarUrl,
    body: item['body'] as String? ?? '',
    createdAt:
        DateTime.tryParse(item['createdAt'] as String? ?? '') ??
        DateTime.now(),
    likeCount: (item['likesCount'] as num?)?.toInt() ?? 0,
    isLikedByMe: item['isLikedByMe'] == true,
    replies: repliesJson
        .whereType<Map<String, dynamic>>()
        .map<SiteCommentItem>(_siteCommentFromJson)
        .toList(),
    repliesCount: (item['repliesCount'] as num?)?.toInt() ?? 0,
  );
}

SiteCommentLikeSnapshot _siteCommentLikeSnapshotFromJson(
  Map<String, dynamic>? json,
) {
  if (json == null) throw AppError.unknown();
  return SiteCommentLikeSnapshot(
    commentId: json['commentId'] as String? ?? '',
    likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
    isLikedByMe: json['isLikedByMe'] == true,
  );
}
