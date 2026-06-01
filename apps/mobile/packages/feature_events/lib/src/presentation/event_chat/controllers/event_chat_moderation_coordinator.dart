part of 'package:feature_events/src/presentation/screens/event_chat_screen.dart';

extension EventChatModerationCoordinator on _EventChatScreenState {
  void _removeMessagesByAuthorId(String authorId) {
    rebuildState(() {
      _messages.removeWhere((EventChatMessage m) => m.authorId == authorId);
      _searchServerHits.removeWhere(
        (EventChatMessage m) => m.authorId == authorId,
      );
      _pinned.removeWhere((EventChatMessage m) => m.authorId == authorId);
      if (_replyTo?.authorId == authorId) {
        _replyTo = null;
      }
      _grouping = computeEventChatMessageGrouping(_messages);
    });
  }
}
