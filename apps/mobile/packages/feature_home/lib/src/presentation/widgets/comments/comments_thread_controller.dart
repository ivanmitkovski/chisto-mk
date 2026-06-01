import 'package:feature_home/src/domain/models/comment.dart';
import 'package:feature_home/src/presentation/widgets/comments/comment_thread_ops.dart';
import 'package:feature_home/src/presentation/widgets/comments/comments_thread_flatten.dart';

/// Mutable comment forest operations for [CommentsBottomSheet].
class CommentsThreadController {
  CommentsThreadController({required List<Comment> initial})
    : comments = List<Comment>.from(initial);

  List<Comment> comments;

  int get totalCount => countCommentNodes(comments);

  void replaceFromWidget(List<Comment> incoming) {
    comments = List<Comment>.from(incoming);
  }

  bool syncFromWidgetIfCompatible(List<Comment> incoming) {
    if (sameRootCommentOrder(incoming, comments)) {
      return false;
    }
    if (incoming.length > comments.length &&
        prefixRootIdsMatch(incoming, comments, comments.length)) {
      comments = List<Comment>.from(incoming);
      return true;
    }
    comments = List<Comment>.from(incoming);
    return true;
  }

  List<Comment> snapshot() => cloneCommentForest(comments);

  void restore(List<Comment> before) {
    comments
      ..clear()
      ..addAll(before);
  }

  bool insertReply(String parentId, Comment reply) =>
      insertReplyInto(comments, parentId, reply);

  bool removeNode(String id) => removeCommentNode(comments, id);

  int removeByAuthor(String authorId) =>
      removeCommentsByAuthorId(comments, authorId);

  bool updateNode(String id, Comment Function(Comment current) transform) =>
      updateCommentNode(comments, id, transform);

  bool mergeDirectReplies(String parentId, List<Comment> incoming) =>
      mergeDirectRepliesInto(comments, parentId, incoming);

  Comment? findById(String id) => findCommentById(comments, id);
}
