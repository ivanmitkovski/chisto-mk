import 'package:chisto_mobile/features/home/domain/models/comment.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/comments/comments_thread_flatten.dart';

/// Parent comment ids that must be expanded to reveal [targetCommentId].
List<String> findCommentAncestorIds(
  List<Comment> comments,
  String targetCommentId,
) {
  final List<String> ancestors = <String>[];
  if (_findPath(comments, targetCommentId, ancestors)) {
    return ancestors;
  }
  return const <String>[];
}

bool _findPath(
  List<Comment> comments,
  String targetCommentId,
  List<String> ancestors,
) {
  for (final Comment comment in comments) {
    if (comment.id == targetCommentId) {
      return true;
    }
    ancestors.add(comment.id);
    if (_findPath(comment.replies, targetCommentId, ancestors)) {
      return true;
    }
    ancestors.removeLast();
  }
  return false;
}

/// Newest top-level comment authored by [actorUserId], if any (legacy notification fallback).
String? findNewestRootCommentIdByActor(
  List<Comment> comments,
  String actorUserId,
) {
  Comment? match;
  for (final Comment comment in comments) {
    if (comment.parentId != null) continue;
    if (!_commentMatchesActor(comment, actorUserId)) continue;
    if (match == null || comment.createdAt.isAfter(match.createdAt)) {
      match = comment;
    }
  }
  return match?.id;
}

bool _commentMatchesActor(Comment comment, String actorUserId) {
  final String? id = comment.authorId?.trim();
  return id != null && id.isNotEmpty && id == actorUserId;
}

/// Resolves which comment id to highlight from notification payload + loaded thread.
String? resolveHighlightCommentId({
  required List<Comment> comments,
  String? commentId,
  String? actorUserId,
}) {
  final String? trimmedCommentId = commentId?.trim();
  if (trimmedCommentId != null && trimmedCommentId.isNotEmpty) {
    return trimmedCommentId;
  }
  final String? trimmedActorId = actorUserId?.trim();
  if (trimmedActorId == null || trimmedActorId.isEmpty) {
    return null;
  }
  return findNewestRootCommentIdByActor(comments, trimmedActorId);
}

int? flattenedCommentIndex(
  List<Comment> comments,
  Set<String> expandedReplyIds,
  String targetCommentId,
) {
  final List<FlattenedComment> flat = flattenCommentThread(
    comments,
    expandedReplyIds,
  );
  for (int i = 0; i < flat.length; i++) {
    if (flat[i].comment.id == targetCommentId) {
      return i;
    }
  }
  return null;
}
