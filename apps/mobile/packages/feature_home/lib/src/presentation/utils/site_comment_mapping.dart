import 'dart:math' show max;

import 'package:feature_home/src/domain/models/comment.dart';
import 'package:feature_home/src/domain/repositories/sites_repository.dart';

Comment commentFromSiteCommentItem(String currentUserId, SiteCommentItem item) {
  final int resolvedRepliesCount = max(item.repliesCount, item.replies.length);
  return Comment(
    id: item.id,
    authorId: item.authorId.isNotEmpty ? item.authorId : null,
    authorName: item.authorName,
    authorIsDeleted: item.authorIsDeleted,
    authorAvatarUrl: item.authorAvatarUrl,
    text: item.body,
    createdAt: item.createdAt,
    parentId: item.parentId,
    likeCount: item.likeCount,
    isLikedByMe: item.isLikedByMe,
    isOwnedByMe: item.authorId == currentUserId,
    replies: item.replies
        .map(
          (SiteCommentItem reply) =>
              commentFromSiteCommentItem(currentUserId, reply),
        )
        .toList(),
    repliesCount: resolvedRepliesCount,
  );
}
