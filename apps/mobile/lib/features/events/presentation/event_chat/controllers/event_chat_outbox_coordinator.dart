part of 'package:chisto_mobile/features/events/presentation/screens/event_chat_screen.dart';

extension EventChatOutboxMixin on _EventChatScreenState {
    void _dedupMessages() {
      final Set<String> seen = <String>{};
      final List<int> dupes = <int>[];
      for (int i = 0; i < _messages.length; i++) {
        if (!seen.add(_messages[i].id)) {
          dupes.add(i);
        }
      }
      for (int i = dupes.length - 1; i >= 0; i--) {
        _messages.removeAt(dupes[i]);
      }
    }

    /// Keeps [_messages] id-unique and drops stale [GlobalKey]s for removed ids.
    void _normalizeMessageList() {
      _dedupMessages();
      _pruneBubbleKeys();
    }

    EventChatMessage? _latestCommittedMessage() {
      for (int i = _messages.length - 1; i >= 0; i--) {
        if (!_messages[i].pending) {
          return _messages[i];
        }
      }
      return null;
    }

    bool _messageStrictlyAfter(EventChatMessage a, EventChatMessage b) {
      final int c = a.createdAt.compareTo(b.createdAt);
      if (c != 0) {
        return c > 0;
      }
      return a.id.compareTo(b.id) > 0;
    }

    Future<void> _markReadBestEffort() async {
      final EventChatMessage? last = _latestCommittedMessage();
      if (last == null) {
        return;
      }
      try {
        final result = await _repo.markRead(widget.eventId, last.id);
        await EventChatNotificationSync.afterMarkRead(
          eventId: widget.eventId,
          result: result,
        );
      } on Object catch (_) {
        logEventsDiagnostic('chat_mark_read_failed');
      }
    }

    /// If realtime missed messages, local last read lags the server — extend cursor to newest on server.
    Future<void> _syncReadCursorWithServerIfAhead() async {
      try {
        final r = await _repo.fetchMessages(widget.eventId, limit: 1);
        if (r.messages.isEmpty) {
          return;
        }
        final EventChatMessage serverNewest = r.messages.first;
        final EventChatMessage? localLast = _latestCommittedMessage();
        if (localLast == null) {
          final result = await _repo.markRead(widget.eventId, serverNewest.id);
          await EventChatNotificationSync.afterMarkRead(
            eventId: widget.eventId,
            result: result,
          );
          return;
        }
        if (_messageStrictlyAfter(serverNewest, localLast)) {
          final result = await _repo.markRead(widget.eventId, serverNewest.id);
          await EventChatNotificationSync.afterMarkRead(
            eventId: widget.eventId,
            result: result,
          );
        }
      } on Object catch (_) {
        logEventsDiagnostic('chat_sync_read_cursor_failed');
      }
    }

    Future<void> _finalizeReadCursorOnExit() async {
      await _markReadBestEffort();
      await _syncReadCursorWithServerIfAhead();
    }

    bool _shouldQueueOffline(Object error) {
      if (error is AppError) {
        return error.retryable;
      }
      return true;
    }

    Future<void> _flushOfflineQueue() async {
      const int maxIterationsPerRun = 50;
      for (int n = 0; n < maxIterationsPerRun && mounted; n++) {
        final ChatOutboxEntry? q = await ChatOutboxStore.shared.peekNext(widget.eventId);
        if (q == null) {
          break;
        }
        final ChatOutboxFlushResult res = await ChatOutboxSync.flushOne(
          repo: _repo,
          store: ChatOutboxStore.shared,
          entry: q,
        );
        if (!mounted) {
          return;
        }
        if (res.kind == ChatOutboxFlushKind.sent) {
          final EventChatMessage saved = res.savedMessage!;
          rebuildState(() {
            final int i = _messages.indexWhere((EventChatMessage m) => m.id == q.tempId);
            if (i >= 0) {
              _messages[i] = saved;
            }
            _normalizeMessageList();
          });
          unawaited(_markReadBestEffort());
          continue;
        }
        if (res.kind == ChatOutboxFlushKind.terminalFailed) {
          rebuildState(() {
            final int i = _messages.indexWhere((EventChatMessage m) => m.id == q.tempId);
            if (i >= 0) {
              _messages[i] = _messages[i].copyWith(pending: false, failed: true);
            }
          });
          continue;
        }
        await Future<void>.delayed(
          ChatOutboxSync.retryDelayAfterAttempt(q.attemptCount + 1),
        );
      }
    }

    /// Drops outbox rows whose [clientMessageId] already appears on a committed message.
    Future<void> _pruneOutboxAgainstCommittedMessages() async {
      if (!mounted) {
        return;
      }
      for (final EventChatMessage m in _messages) {
        if (!mounted) {
          return;
        }
        if (m.pending || m.failed) {
          continue;
        }
        final String? c = m.clientMessageId;
        if (c != null && c.isNotEmpty) {
          await ChatOutboxStore.shared.remove(widget.eventId, c);
        }
      }
    }

    /// Restores pending bubbles from SQLite after process death; flushes when online.
    Future<void> _reconcileChatOutboxAfterInitialLoad() async {
      await _pruneOutboxAgainstCommittedMessages();
      final List<ChatOutboxEntry> rows =
          await ChatOutboxStore.shared.listPendingAndFailed(widget.eventId);
      if (rows.isEmpty || !mounted) {
        unawaited(_flushOfflineQueue());
        return;
      }
      bool changed = false;
      for (final ChatOutboxEntry row in rows) {
        final bool hasBubble = _messages.any(
          (EventChatMessage m) => m.id == row.tempId || m.clientMessageId == row.clientMessageId,
        );
        if (hasBubble) {
          continue;
        }
        final EventChatMessage optimistic = EventChatMessage(
          id: row.tempId,
          eventId: widget.eventId,
          authorId: _auth?.userId ?? 'me',
          authorName: _auth?.displayName ?? '…',
          createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAtMs, isUtc: true),
          body: row.body,
          isDeleted: false,
          isOwnMessage: true,
          replyToId: row.replyToId,
          replyToSnippet: null,
          pending: row.isPending,
          failed: row.isFailed,
          messageType: EventChatMessageType.text,
          clientMessageId: row.clientMessageId,
        );
        insertEventChatMessageSorted(_messages, optimistic);
        changed = true;
      }
      if (changed) {
        rebuildState(() {});
      }
      unawaited(_flushOfflineQueue());
    }
}
