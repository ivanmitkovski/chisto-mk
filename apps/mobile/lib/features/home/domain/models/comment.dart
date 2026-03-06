/// Lightweight UI model for a comment on a pollution site post.
class Comment {
  const Comment({
    required this.id,
    required this.authorName,
    required this.text,
    this.likeCount = 0,
    this.isLikedByMe = false,
  });

  final String id;
  final String authorName;
  final String text;
  final int? likeCount;
  final bool? isLikedByMe;

  Comment copyWith({
    String? id,
    String? authorName,
    String? text,
    int? likeCount,
    bool? isLikedByMe,
  }) {
    return Comment(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      text: text ?? this.text,
      likeCount: likeCount ?? this.likeCount ?? 0,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe ?? false,
    );
  }
}
