import 'package:feature_home/src/domain/models/comment.dart';
import 'package:feature_home/src/domain/repositories/sites_repository_types.dart';
import 'package:feature_home/src/presentation/widgets/comments/comment_thread_ops.dart';

/// Resolves the number to show on the feed engagement bar after loading site comments.
///
/// Prefers [SiteCommentsResult.engagementTotal] from the API (viewer-visible roots + replies).
/// Falls back to counting loaded tree nodes when the field is absent (older API).
int commentCountForEngagementAfterFetch({
  required SiteCommentsResult result,
  required List<Comment> mappedComments,
}) {
  final int? engagementTotal = result.engagementTotal;
  if (engagementTotal != null) {
    return engagementTotal;
  }
  return countCommentNodes(mappedComments);
}
