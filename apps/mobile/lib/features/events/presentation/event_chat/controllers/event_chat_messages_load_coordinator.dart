part of 'package:chisto_mobile/features/events/presentation/screens/event_chat_screen.dart';

extension EventChatMessagesLoadMixin on _EventChatScreenState {
    Future<void> _loadInitial() async {
      rebuildState(() {
        _loading = true;
        _loadError = false;
      });
      try {
        final result = await _repo.fetchMessages(widget.eventId, limit: 50);
        final List<EventChatMessage> asc =
            List<EventChatMessage>.from(result.messages.reversed);
        if (!mounted) {
          return;
        }
        rebuildState(() {
          _messages
            ..clear()
            ..addAll(asc);
          _normalizeMessageList();
          _nextOlderCursor = result.nextCursor;
          _hasMoreOlder = result.hasMore;
          _loading = false;
        });
        await _reconcileChatOutboxAfterInitialLoad();
        if (!mounted) {
          return;
        }
        unawaited(_markReadBestEffort());
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animated: false));
      } on Object catch (_) {
        if (!mounted) {
          return;
        }
        logEventsDiagnostic('chat_load_initial_failed');
        rebuildState(() {
          _loading = false;
          _loadError = true;
        });
      }
    }

    Future<void> _loadOlder() async {
      if (_loadingOlder || !_hasMoreOlder || _nextOlderCursor == null) {
        return;
      }
      rebuildState(() => _loadingOlder = true);
      try {
        final result = await _repo.fetchMessages(
          widget.eventId,
          cursor: _nextOlderCursor,
          limit: 50,
        );
        if (!mounted) {
          return;
        }
        final List<EventChatMessage> older =
            List<EventChatMessage>.from(result.messages.reversed);
        rebuildState(() {
          _messages.insertAll(0, older);
          _messages.sort(compareEventChatMessagesChronological);
          _normalizeMessageList();
          _nextOlderCursor = result.nextCursor;
          _hasMoreOlder = result.hasMore;
          _loadingOlder = false;
        });
      } on Object catch (_) {
        if (mounted) {
          logEventsDiagnostic('chat_load_older_failed');
          rebuildState(() => _loadingOlder = false);
        }
      }
    }
}
