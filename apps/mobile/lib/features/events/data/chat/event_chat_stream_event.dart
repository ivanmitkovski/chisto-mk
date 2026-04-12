import 'package:flutter/foundation.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_connection_status.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';

@immutable
sealed class EventChatStreamEvent {
  const EventChatStreamEvent();
}

@immutable
class EventChatStreamMessageCreated extends EventChatStreamEvent {
  const EventChatStreamMessageCreated(this.message);

  final EventChatMessage message;
}

@immutable
class EventChatStreamMessageDeleted extends EventChatStreamEvent {
  const EventChatStreamMessageDeleted(this.messageId);

  final String messageId;
}

@immutable
class EventChatStreamMessageEdited extends EventChatStreamEvent {
  const EventChatStreamMessageEdited(this.message);

  final EventChatMessage message;
}

@immutable
class EventChatStreamMessagePinned extends EventChatStreamEvent {
  const EventChatStreamMessagePinned(this.message);

  final EventChatMessage message;
}

@immutable
class EventChatStreamMessageUnpinned extends EventChatStreamEvent {
  const EventChatStreamMessageUnpinned(this.message);

  final EventChatMessage message;
}

@immutable
class EventChatStreamConnectionChanged extends EventChatStreamEvent {
  const EventChatStreamConnectionChanged(this.status);

  final EventChatConnectionStatus status;
}

@immutable
class EventChatStreamTypingUpdated extends EventChatStreamEvent {
  const EventChatStreamTypingUpdated({
    required this.eventId,
    required this.userId,
    required this.displayName,
    required this.typing,
  });

  final String eventId;
  final String userId;
  final String displayName;
  final bool typing;
}

@immutable
class EventChatStreamReadCursorUpdated extends EventChatStreamEvent {
  const EventChatStreamReadCursorUpdated({
    required this.eventId,
    required this.userId,
    required this.displayName,
    this.lastReadMessageId,
    this.lastReadMessageCreatedAt,
  });

  final String eventId;
  final String userId;
  final String displayName;
  final String? lastReadMessageId;
  final DateTime? lastReadMessageCreatedAt;
}
