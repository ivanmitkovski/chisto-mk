import 'package:chisto_mobile/features/home/domain/models/comment.dart';

int countCommentNodes(List<Comment> roots) {
  int total = 0;
  for (final Comment comment in roots) {
    total += 1 + countCommentNodes(comment.replies);
  }
  return total;
}

bool insertReplyInto(List<Comment> nodes, String parentId, Comment reply) {
  for (int i = 0; i < nodes.length; i++) {
    final Comment node = nodes[i];
    if (node.id == parentId) {
      nodes[i] = node.copyWith(replies: <Comment>[reply, ...node.replies]);
      return true;
    }
    final List<Comment> mutableReplies = List<Comment>.from(node.replies);
    if (insertReplyInto(mutableReplies, parentId, reply)) {
      nodes[i] = node.copyWith(replies: mutableReplies);
      return true;
    }
  }
  return false;
}

bool removeCommentNode(List<Comment> nodes, String id) {
  final int index = nodes.indexWhere((Comment c) => c.id == id);
  if (index >= 0) {
    nodes.removeAt(index);
    return true;
  }
  for (int i = 0; i < nodes.length; i++) {
    final Comment node = nodes[i];
    final List<Comment> mutableReplies = List<Comment>.from(node.replies);
    if (removeCommentNode(mutableReplies, id)) {
      nodes[i] = node.copyWith(replies: mutableReplies);
      return true;
    }
  }
  return false;
}

List<Comment> cloneCommentForest(List<Comment> nodes) {
  return nodes
      .map(
        (Comment node) =>
            node.copyWith(replies: cloneCommentForest(node.replies)),
      )
      .toList();
}

Comment? findCommentById(List<Comment> nodes, String id) {
  for (final Comment node in nodes) {
    if (node.id == id) {
      return node;
    }
    final Comment? nested = findCommentById(node.replies, id);
    if (nested != null) {
      return nested;
    }
  }
  return null;
}

bool updateCommentNode(
  List<Comment> nodes,
  String id,
  Comment Function(Comment current) transform,
) {
  for (int i = 0; i < nodes.length; i++) {
    final Comment node = nodes[i];
    if (node.id == id) {
      nodes[i] = transform(node);
      return true;
    }
    final List<Comment> replies = List<Comment>.from(node.replies);
    if (updateCommentNode(replies, id, transform)) {
      nodes[i] = node.copyWith(replies: replies);
      return true;
    }
  }
  return false;
}

bool mergeDirectRepliesInto(
  List<Comment> nodes,
  String parentId,
  List<Comment> incoming,
) {
  for (int i = 0; i < nodes.length; i++) {
    final Comment c = nodes[i];
    if (c.id == parentId) {
      final Set<String> ids = <String>{for (final Comment x in c.replies) x.id};
      final List<Comment> merged = List<Comment>.from(c.replies);
      for (final Comment n in incoming) {
        if (!ids.contains(n.id)) {
          merged.add(n);
          ids.add(n.id);
        }
      }
      nodes[i] = c.copyWith(replies: merged);
      return true;
    }
    final List<Comment> childList = List<Comment>.from(c.replies);
    if (mergeDirectRepliesInto(childList, parentId, incoming)) {
      nodes[i] = c.copyWith(replies: childList);
      return true;
    }
  }
  return false;
}
