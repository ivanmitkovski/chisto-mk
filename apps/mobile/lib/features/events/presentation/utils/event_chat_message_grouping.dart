import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_theme.dart';

/// Bubble cluster + date-separator metadata for one row in the reversed chat list.
class EventChatMessageGroupingInfo {
  const EventChatMessageGroupingInfo({
    required this.isFirst,
    required this.isLast,
    required this.showDate,
  });

  final bool isFirst;
  final bool isLast;
  final bool showDate;
}

bool _sameDay(DateTime a, DateTime b) {
  final DateTime la = a.toLocal();
  final DateTime lb = b.toLocal();
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}

bool _sameChatGroup(List<EventChatMessage> messages, int a, int b) {
  if (a < 0 || b < 0 || a >= messages.length || b >= messages.length) {
    return false;
  }
  final EventChatMessage ma = messages[a];
  final EventChatMessage mb = messages[b];
  if (ma.messageType == EventChatMessageType.system || mb.messageType == EventChatMessageType.system) {
    return false;
  }
  return ma.authorId == mb.authorId && ma.isOwnMessage == mb.isOwnMessage;
}

bool _isFirstInGroup(List<EventChatMessage> messages, int i) {
  final EventChatMessage m = messages[i];
  if (m.messageType == EventChatMessageType.system) {
    return true;
  }
  int p = i - 1;
  while (p >= 0 && messages[p].messageType == EventChatMessageType.system) {
    p--;
  }
  if (p < 0) {
    return true;
  }
  return !_sameChatGroup(messages, i, p);
}

bool _isLastInGroup(List<EventChatMessage> messages, int i) {
  final EventChatMessage m = messages[i];
  if (m.messageType == EventChatMessageType.system) {
    return true;
  }
  int n = i + 1;
  while (n < messages.length && messages[n].messageType == EventChatMessageType.system) {
    n++;
  }
  if (n >= messages.length) {
    return true;
  }
  return !_sameChatGroup(messages, i, n);
}

/// Recomputes grouping whenever [_messages] changes (reverse list order).
List<EventChatMessageGroupingInfo> computeEventChatMessageGrouping(List<EventChatMessage> messages) {
  return List<EventChatMessageGroupingInfo>.generate(messages.length, (int i) {
    final bool first = _isFirstInGroup(messages, i);
    final bool last = _isLastInGroup(messages, i);
    final bool date = i == 0 || !_sameDay(messages[i].createdAt, messages[i - 1].createdAt);
    return EventChatMessageGroupingInfo(isFirst: first, isLast: last, showDate: date);
  });
}

/// Vertical gap below message at [i] toward the next newer message (reverse list).
double eventChatBubbleGapBelow({
  required List<EventChatMessage> messages,
  required List<EventChatMessageGroupingInfo> grouping,
  required int i,
}) {
  if (i < 0 || i >= messages.length - 1) {
    return 0;
  }
  final bool newerOpensDay = i + 1 < grouping.length && grouping[i + 1].showDate;
  if (newerOpensDay) {
    return ChatTheme.bubbleStackGapBetweenClusters;
  }
  return _sameChatGroup(messages, i, i + 1)
      ? ChatTheme.bubbleStackGapWithinCluster
      : ChatTheme.bubbleStackGapBetweenClusters;
}
