import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';

/// Ascending order: oldest first (same comparator previously used with [List.sort] on the chat screen).
int compareEventChatMessagesChronological(EventChatMessage a, EventChatMessage b) {
  final int c = a.createdAt.compareTo(b.createdAt);
  if (c != 0) {
    return c;
  }
  return a.id.compareTo(b.id);
}

/// Inserts [message] in ascending order. Caller must ensure no duplicate [EventChatMessage.id] exists if that is required.
void insertEventChatMessageSorted(List<EventChatMessage> list, EventChatMessage message) {
  int lo = 0;
  int hi = list.length;
  while (lo < hi) {
    final int mid = (lo + hi) >> 1;
    if (compareEventChatMessagesChronological(list[mid], message) < 0) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  list.insert(lo, message);
}
