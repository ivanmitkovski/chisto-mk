import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';

/// Messages in [messages] whose non-empty [EventChatMessage.body] contains [query]
/// (case-insensitive). Excludes deleted rows. Matches [InMemoryEventChatRepository.searchMessages].
List<EventChatMessage> localEventChatSearchMatches(
  List<EventChatMessage> messages,
  String query,
) {
  final String q = query.trim();
  if (q.length < 2) {
    return <EventChatMessage>[];
  }
  final String lowerQ = q.toLowerCase();
  return messages.where((EventChatMessage m) {
    if (m.isDeleted) {
      return false;
    }
    final String? b = m.body;
    if (b == null || b.trim().isEmpty) {
      return false;
    }
    return b.toLowerCase().contains(lowerQ);
  }).toList();
}

/// Prefer the live copy from [allMessages] when the same [EventChatMessage.id] exists.
List<EventChatMessage> mergeEventChatSearchHits({
  required List<EventChatMessage> serverHits,
  required List<EventChatMessage> allMessages,
  required String query,
}) {
  final Map<String, EventChatMessage> liveById = <String, EventChatMessage>{
    for (final EventChatMessage m in allMessages) m.id: m,
  };
  final Map<String, EventChatMessage> byId = <String, EventChatMessage>{};
  for (final EventChatMessage s in serverHits) {
    byId[s.id] = liveById[s.id] ?? s;
  }
  for (final EventChatMessage m in localEventChatSearchMatches(allMessages, query)) {
    byId[m.id] = liveById[m.id] ?? m;
  }
  final List<EventChatMessage> out = byId.values.toList();
  out.sort((EventChatMessage a, EventChatMessage b) {
    final int c = b.createdAt.compareTo(a.createdAt);
    if (c != 0) {
      return c;
    }
    return b.id.compareTo(a.id);
  });
  return out;
}

/// True when [merged] contains at least one message not present in [serverHits] by id.
bool eventChatSearchMergedIncludesLocalOnly({
  required List<EventChatMessage> serverHits,
  required List<EventChatMessage> merged,
}) {
  if (merged.isEmpty) {
    return false;
  }
  final Set<String> serverIds = serverHits.map((EventChatMessage m) => m.id).toSet();
  return merged.any((EventChatMessage m) => !serverIds.contains(m.id));
}
