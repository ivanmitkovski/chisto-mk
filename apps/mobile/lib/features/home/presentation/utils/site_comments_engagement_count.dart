import 'dart:math' as math;

import 'package:chisto_mobile/features/home/domain/models/comment.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/comments/comment_thread_ops.dart';

/// Resolves the number to show on the feed engagement bar after loading site comments.
///
/// [SiteCommentsResult.total] is the count of **root** comments (pagination). The loaded
/// [mappedComments] tree includes nested replies, so we take [max] of both. We intentionally
/// do **not** merge in [PollutionSite.commentsCount]: it can stay high after deletes until
/// the next full feed refresh; [patchPollutionSitesCommentsCount] keeps the feed model in sync.
int commentCountForEngagementAfterFetch({
  required SiteCommentsResult result,
  required List<Comment> mappedComments,
}) {
  final int fromThread = countCommentNodes(mappedComments);
  return math.max(result.total, fromThread);
}
