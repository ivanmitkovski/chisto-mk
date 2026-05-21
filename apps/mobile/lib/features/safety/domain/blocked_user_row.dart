/// A user blocked by the authenticated citizen (`GET /users/me/blocks`).
class BlockedUserRow {
  const BlockedUserRow({
    required this.blockedUserId,
    required this.displayName,
    this.createdAt,
  });

  final String blockedUserId;
  final String displayName;
  final DateTime? createdAt;

  static BlockedUserRow fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? blocked =
        json['blocked'] as Map<String, dynamic>?;
    final String blockedUserId =
        (json['blockedUserId'] as String? ?? blocked?['id'] as String? ?? '').trim();
    final String first = blocked?['firstName'] as String? ?? '';
    final String last = blocked?['lastName'] as String? ?? '';
    final String name = '$first $last'.trim();
    final String? createdRaw = json['createdAt'] as String?;
    return BlockedUserRow(
      blockedUserId: blockedUserId,
      displayName: name.isNotEmpty ? name : blockedUserId,
      createdAt: createdRaw == null ? null : DateTime.tryParse(createdRaw),
    );
  }
}
