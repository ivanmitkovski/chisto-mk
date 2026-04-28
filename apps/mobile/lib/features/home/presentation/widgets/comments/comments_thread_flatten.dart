import 'package:chisto_mobile/features/home/domain/models/comment.dart';

/// One row in a flattened comment thread (root or nested reply).
class FlattenedComment {
  const FlattenedComment({required this.comment, required this.depth});

  final Comment comment;
  final int depth;
}

/// Depth-first list of comments respecting [expandedReplyIds].
List<FlattenedComment> flattenCommentThread(
  List<Comment> comments,
  Set<String> expandedReplyIds, {
  int depth = 0,
}) {
  final List<FlattenedComment> out = <FlattenedComment>[];
  for (final Comment comment in comments) {
    out.add(FlattenedComment(comment: comment, depth: depth));
    if (expandedReplyIds.contains(comment.id)) {
      out.addAll(
        flattenCommentThread(
          comment.replies,
          expandedReplyIds,
          depth: depth + 1,
        ),
      );
    }
  }
  return out;
}

bool sameRootCommentOrder(List<Comment> a, List<Comment> b) {
  if (a.length != b.length) {
    return false;
  }
  for (int i = 0; i < a.length; i++) {
    if (a[i].id != b[i].id) {
      return false;
    }
  }
  return true;
}

bool prefixRootIdsMatch(
  List<Comment> longer,
  List<Comment> prefix,
  int prefixLen,
) {
  if (prefixLen <= 0) {
    return true;
  }
  if (longer.length < prefixLen || prefix.length < prefixLen) {
    return false;
  }
  for (int i = 0; i < prefixLen; i++) {
    if (longer[i].id != prefix[i].id) {
      return false;
    }
  }
  return true;
}
