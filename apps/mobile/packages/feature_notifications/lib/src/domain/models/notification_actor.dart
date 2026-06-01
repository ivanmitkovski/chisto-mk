class NotificationActor {
  const NotificationActor({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  factory NotificationActor.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError.notNull('json');
    }
    final String? url = json['avatarUrl'] as String?;
    return NotificationActor(
      id: json['id'] as String? ?? '',
      displayName: (json['displayName'] as String? ?? '').trim(),
      avatarUrl: url != null && url.trim().isNotEmpty ? url.trim() : null,
    );
  }

  final String id;
  final String displayName;
  final String? avatarUrl;
}
