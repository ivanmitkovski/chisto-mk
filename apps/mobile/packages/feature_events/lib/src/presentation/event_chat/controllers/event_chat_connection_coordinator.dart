part of 'package:feature_events/src/presentation/screens/event_chat_screen.dart';

extension EventChatConnectionMixin on _EventChatScreenState {
  Future<void> _mergeLatestFromServer() async {
    try {
      final r = await _repo.fetchMessages(widget.eventId, limit: 20);
      final List<EventChatMessage> incoming = List<EventChatMessage>.from(
        r.messages.reversed,
      );
      if (!mounted) {
        return;
      }
      final Set<String> beforeIds = _messages
          .map((EventChatMessage m) => m.id)
          .toSet();
      final List<String> newIds = incoming
          .map((EventChatMessage m) => m.id)
          .where((String id) => !beforeIds.contains(id))
          .toList();
      rebuildState(() {
        final Set<String> ids = _messages
            .map((EventChatMessage m) => m.id)
            .toSet();
        for (final EventChatMessage m in incoming) {
          if (!ids.contains(m.id)) {
            insertEventChatMessageSorted(_messages, m);
            ids.add(m.id);
          }
        }
        _normalizeMessageList();
      });
      if (kDebugMode && newIds.isNotEmpty) {
        final String sample = newIds.take(4).join(', ');
        AppLog.verbose(
          '[chat:poll] +${newIds.length} message(s) event=${widget.eventId} '
          'ids=[$sample${newIds.length > 4 ? ', …' : ''}]',
        );
      }
    } on Object catch (_) {
      logEventsDiagnostic('chat_merge_poll_failed');
    }
    unawaited(_loadReadCursors());
    if (mounted) {
      unawaited(_pruneOutboxAgainstCommittedMessages());
    }
  }

  Future<void> _loadReadCursors() async {
    try {
      final List<EventChatReadCursor> list = await _repo.fetchReadCursors(
        widget.eventId,
      );
      if (mounted) {
        rebuildState(() => _readCursors = list);
      }
    } on Object catch (_) {
      logEventsDiagnostic('chat_load_read_cursors_failed');
    }
  }
}
