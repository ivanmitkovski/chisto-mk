/// Server meta from `PATCH /events/:id/chat/read`.
class EventChatMarkReadResult {
  const EventChatMarkReadResult({
    this.unreadCount,
    this.eventChatNotificationsMarkedRead,
  });

  final int? unreadCount;
  final int? eventChatNotificationsMarkedRead;

  static EventChatMarkReadResult? fromResponseJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final Object? meta = json['meta'];
    if (meta is! Map<String, dynamic>) return null;
    final Object? unread = meta['unreadCount'];
    final Object? marked = meta['eventChatNotificationsMarkedRead'];
    return EventChatMarkReadResult(
      unreadCount: unread is num ? unread.toInt() : null,
      eventChatNotificationsMarkedRead: marked is num ? marked.toInt() : null,
    );
  }
}
