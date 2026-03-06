enum FeedNotificationType {
  update,
  action,
  system,
}

class FeedNotification {
  const FeedNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    this.isRead = false,
    this.targetSiteId,
    this.targetTabIndex,
  });

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final FeedNotificationType type;
  final bool isRead;
  final String? targetSiteId;
  final int? targetTabIndex;

  FeedNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? createdAt,
    FeedNotificationType? type,
    bool? isRead,
    String? targetSiteId,
    int? targetTabIndex,
  }) {
    return FeedNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      targetSiteId: targetSiteId ?? this.targetSiteId,
      targetTabIndex: targetTabIndex ?? this.targetTabIndex,
    );
  }
}
