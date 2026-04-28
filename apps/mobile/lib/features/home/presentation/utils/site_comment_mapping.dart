import 'dart:math' show max;

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/features/home/domain/models/comment.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository.dart';

Comment commentFromSiteCommentItem(SiteCommentItem item) {
  final String currentUserId = ServiceLocator.instance.authState.userId ?? '';
  final int resolvedRepliesCount = max(item.repliesCount, item.replies.length);
  return Comment(
    id: item.id,
    authorName: item.authorName,
    authorAvatarUrl: item.authorAvatarUrl,
    text: item.body,
    createdAt: item.createdAt,
    parentId: item.parentId,
    likeCount: item.likeCount,
    isLikedByMe: item.isLikedByMe,
    isOwnedByMe: item.authorId == currentUserId,
    replies: item.replies.map(commentFromSiteCommentItem).toList(),
    repliesCount: resolvedRepliesCount,
  );
}
