import 'package:flutter/foundation.dart';

@immutable
class EventChatReadCursor {
  const EventChatReadCursor({
    required this.userId,
    required this.displayName,
    this.lastReadMessageId,
    this.lastReadMessageCreatedAt,
  });

  final String userId;
  final String displayName;
  final String? lastReadMessageId;
  final DateTime? lastReadMessageCreatedAt;

  EventChatReadCursor copyWith({
    String? userId,
    String? displayName,
    String? lastReadMessageId,
    DateTime? lastReadMessageCreatedAt,
  }) {
    return EventChatReadCursor(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      lastReadMessageId: lastReadMessageId ?? this.lastReadMessageId,
      lastReadMessageCreatedAt: lastReadMessageCreatedAt ?? this.lastReadMessageCreatedAt,
    );
  }

  static EventChatReadCursor? tryFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    final Object? userId = json['userId'];
    final Object? displayName = json['displayName'];
    if (userId is! String || displayName is! String) {
      return null;
    }
    final Object? lastId = json['lastReadMessageId'];
    final Object? lastCreated = json['lastReadMessageCreatedAt'];
    DateTime? at;
    if (lastCreated is String && lastCreated.isNotEmpty) {
      at = DateTime.tryParse(lastCreated);
    }
    return EventChatReadCursor(
      userId: userId,
      displayName: displayName,
      lastReadMessageId: lastId is String ? lastId : null,
      lastReadMessageCreatedAt: at,
    );
  }
}
