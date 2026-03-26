/// Lightweight UI model for a comment on a pollution site post.
class Comment {
  const Comment({
    required this.id,
    required this.authorName,
    required this.text,
    this.parentId,
    this.replies = const <Comment>[],
    this.likeCount = 0,
    this.isLikedByMe = false,
    this.isOwnedByMe = false,
  });

  final String id;
  final String authorName;
  final String text;
  final String? parentId;
  final List<Comment> replies;
  final int? likeCount;
  final bool? isLikedByMe;
  final bool isOwnedByMe;

  Comment copyWith({
    String? id,
    String? authorName,
    String? text,
    String? parentId,
    List<Comment>? replies,
    int? likeCount,
    bool? isLikedByMe,
    bool? isOwnedByMe,
  }) {
    return Comment(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      text: text ?? this.text,
      parentId: parentId ?? this.parentId,
      replies: replies ?? this.replies,
      likeCount: likeCount ?? this.likeCount ?? 0,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe ?? false,
      isOwnedByMe: isOwnedByMe ?? this.isOwnedByMe,
    );
  }
}
