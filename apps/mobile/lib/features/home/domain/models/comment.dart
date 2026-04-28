/// Lightweight UI model for a comment on a pollution site post.
class Comment {
  Comment({
    required this.id,
    required this.authorName,
    this.authorAvatarUrl,
    required this.text,
    required this.createdAt,
    this.parentId,
    this.replies = const <Comment>[],
    this.repliesCount = 0,
    this.likeCount = 0,
    this.isLikedByMe = false,
    this.isOwnedByMe = false,
  });

  final String id;
  final String authorName;
  final String? authorAvatarUrl;
  final String text;
  /// Server time for the comment body (optimistic rows use [DateTime.now] until replaced).
  final DateTime createdAt;
  final String? parentId;
  final List<Comment> replies;

  /// Total direct replies on the server (may exceed [replies.length] when inlined cap applies).
  final int repliesCount;
  final int? likeCount;
  final bool? isLikedByMe;
  final bool isOwnedByMe;

  Comment copyWith({
    String? id,
    String? authorName,
    String? authorAvatarUrl,
    String? text,
    DateTime? createdAt,
    String? parentId,
    List<Comment>? replies,
    int? repliesCount,
    int? likeCount,
    bool? isLikedByMe,
    bool? isOwnedByMe,
  }) {
    return Comment(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      parentId: parentId ?? this.parentId,
      replies: replies ?? this.replies,
      repliesCount: repliesCount ?? this.repliesCount,
      likeCount: likeCount ?? this.likeCount ?? 0,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe ?? false,
      isOwnedByMe: isOwnedByMe ?? this.isOwnedByMe,
    );
  }
}
