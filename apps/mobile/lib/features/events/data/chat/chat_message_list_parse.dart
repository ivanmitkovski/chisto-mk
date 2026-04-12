import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';

/// Serializable argument for [parseEventChatMessageBatch] (used with [compute]).
class ChatMessageListParseArg {
  const ChatMessageListParseArg({
    required this.rawMaps,
    this.viewerUserId,
  });

  final List<Map<String, dynamic>> rawMaps;
  final String? viewerUserId;
}

/// Top-level for [compute] / isolate — keep in sync with in-process parsing.
List<EventChatMessage> parseEventChatMessageBatch(ChatMessageListParseArg arg) {
  final String? uid = arg.viewerUserId;
  return arg.rawMaps
      .map(EventChatMessage.tryFromJson)
      .whereType<EventChatMessage>()
      .map((EventChatMessage m) => m.withViewer(uid))
      .toList();
}
