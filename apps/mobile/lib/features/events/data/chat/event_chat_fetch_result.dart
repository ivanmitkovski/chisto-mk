import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';

/// Paginated chat history (newest messages first in [messages]).
class EventChatFetchResult {
  const EventChatFetchResult({
    required this.messages,
    required this.hasMore,
    this.nextCursor,
  });

  final List<EventChatMessage> messages;
  final bool hasMore;
  final String? nextCursor;
}
