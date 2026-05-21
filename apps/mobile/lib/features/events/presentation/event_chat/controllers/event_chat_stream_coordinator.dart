part of 'package:chisto_mobile/features/events/presentation/screens/event_chat_screen.dart';

extension EventChatStreamMixin on _EventChatScreenState {
    int _matchPendingIndexForIncoming(EventChatMessage m) {
      final String? cm = m.clientMessageId;
      if (cm != null && cm.isNotEmpty) {
        final int byClient = _messages.indexWhere(
          (EventChatMessage x) =>
              x.pending &&
              x.authorId == m.authorId &&
              x.clientMessageId != null &&
              x.clientMessageId == cm,
        );
        if (byClient >= 0) {
          return byClient;
        }
      }
      if (m.messageType == EventChatMessageType.audio) {
        final int audioIdx = _indexOfPendingOwnVoiceNote(m);
        if (audioIdx >= 0) {
          return audioIdx;
        }
      }
      if (m.messageType == EventChatMessageType.image ||
          m.messageType == EventChatMessageType.file ||
          m.messageType == EventChatMessageType.video) {
        if (m.attachments.isNotEmpty) {
          final int mediaIdx = _indexOfPendingOwnMediaMessage(m);
          if (mediaIdx >= 0) {
            return mediaIdx;
          }
        }
      }
      return _messages.indexWhere((EventChatMessage x) =>
          x.pending == true &&
          x.authorId == m.authorId &&
          x.body?.trim() == m.body?.trim());
    }

    /// Picks the pending row for SSE image/file/video when several empty-body sends are in flight.
    int _indexOfPendingOwnMediaMessage(EventChatMessage m) {
      final List<int> candidates = <int>[];
      for (int i = 0; i < _messages.length; i++) {
        final EventChatMessage x = _messages[i];
        if (!x.pending || x.authorId != m.authorId) {
          continue;
        }
        if (x.messageType != m.messageType) {
          continue;
        }
        if (x.attachments.length != m.attachments.length) {
          continue;
        }
        if ((x.body ?? '').trim() != (m.body ?? '').trim()) {
          continue;
        }
        candidates.add(i);
      }
      if (candidates.isEmpty) {
        return -1;
      }
      if (candidates.length == 1) {
        return candidates.single;
      }
      final int serverSum =
          m.attachments.fold<int>(0, (int a, EventChatAttachment c) => a + c.sizeBytes);
      for (final int i in candidates) {
        final int localSum = _messages[i]
            .attachments
            .fold<int>(0, (int a, EventChatAttachment c) => a + c.sizeBytes);
        if (localSum == serverSum) {
          return i;
        }
      }
      return candidates.first;
    }

    /// Resolves which pending row an SSE-created audio message should replace when
    /// several empty-body voice sends are in flight.
    int _indexOfPendingOwnVoiceNote(EventChatMessage m) {
      final EventChatAttachment? serverA =
          m.attachments.isEmpty ? null : m.attachments.first;
      if (serverA == null) {
        return -1;
      }
      final List<int> candidates = <int>[];
      for (int i = 0; i < _messages.length; i++) {
        final EventChatMessage x = _messages[i];
        if (!x.pending || x.authorId != m.authorId) {
          continue;
        }
        if (x.messageType != EventChatMessageType.audio) {
          continue;
        }
        if (x.attachments.isEmpty) {
          continue;
        }
        final EventChatAttachment la = x.attachments.first;
        if (!la.mimeType.toLowerCase().startsWith('audio/')) {
          continue;
        }
        candidates.add(i);
      }
      if (candidates.isEmpty) {
        return -1;
      }
      if (candidates.length == 1) {
        return candidates.single;
      }
      for (final int i in candidates) {
        final EventChatAttachment la = _messages[i].attachments.first;
        final int? ld = la.duration;
        final int? sd = serverA.duration;
        if (ld != null && sd != null && (ld - sd).abs() <= 1) {
          return i;
        }
      }
      for (final int i in candidates) {
        final EventChatAttachment la = _messages[i].attachments.first;
        if (la.sizeBytes > 0 && la.sizeBytes == serverA.sizeBytes) {
          return i;
        }
      }
      return candidates.first;
    }

    void _onStreamEvent(EventChatStreamEvent e) {
      if (!mounted) {
        return;
      }
      if (e is EventChatStreamMessageCreated) {
        final EventChatMessage m = e.message;
        final int idx = _messages.indexWhere((EventChatMessage x) => x.id == m.id);
        if (idx >= 0) {
          rebuildState(() => _messages[idx] = m);
        } else {
          // SSE may arrive before the POST response — match the pending
          // optimistic message by author + body (or audio heuristics) to prevent duplicates.
          final int pendingIdx = _matchPendingIndexForIncoming(m);
          if (pendingIdx >= 0) {
            rebuildState(() {
              _messages[pendingIdx] = m;
              _normalizeMessageList();
            });
          } else {
            rebuildState(() {
              insertEventChatMessageSorted(_messages, m);
              _normalizeMessageList();
            });
            if (_nearBottom) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
            } else {
              rebuildState(() => _showNewPill = true);
            }
          }
        }
        unawaited(_markReadBestEffort());
        if (m.messageType == EventChatMessageType.text && m.isPinned) {
          unawaited(_loadPinned());
        }
      } else if (e is EventChatStreamMessageDeleted) {
        if (_audioPlayback.activeClipKey == e.messageId) {
          unawaited(_audioPlayback.stopActiveClip());
        }
        final int idx = _messages.indexWhere((EventChatMessage x) => x.id == e.messageId);
        if (idx >= 0) {
          rebuildState(() {
            _messages[idx] = _messages[idx].copyWith(
              isDeleted: true,
              body: null,
              isPinned: false,
              attachments: const <EventChatAttachment>[],
              locationLat: null,
              locationLng: null,
              locationLabel: null,
            );
          });
        }
        unawaited(_loadPinned());
      } else if (e is EventChatStreamMessageEdited) {
        final EventChatMessage m = e.message;
        final int idx = _messages.indexWhere((EventChatMessage x) => x.id == m.id);
        if (idx >= 0) {
          rebuildState(() => _messages[idx] = m);
        }
      } else if (e is EventChatStreamMessagePinned) {
        final EventChatMessage m = e.message;
        final int idx = _messages.indexWhere((EventChatMessage x) => x.id == m.id);
        if (idx >= 0) {
          rebuildState(() => _messages[idx] = m);
        }
        unawaited(_loadPinned());
      } else if (e is EventChatStreamMessageUnpinned) {
        final EventChatMessage m = e.message;
        final int idx = _messages.indexWhere((EventChatMessage x) => x.id == m.id);
        if (idx >= 0) {
          rebuildState(() => _messages[idx] = m);
        }
        unawaited(_loadPinned());
      } else if (e is EventChatStreamTypingUpdated) {
        final String? me = _auth?.userId;
        if (me != null && e.userId == me) {
          return;
        }
        rebuildState(() {
          if (e.typing) {
            _typingPeers[e.userId] = EventChatTypingPeer(
              displayName: e.displayName,
              until: DateTime.now().add(const Duration(seconds: 6)),
            );
          } else {
            _typingPeers.remove(e.userId);
          }
        });
      } else if (e is EventChatStreamReadCursorUpdated) {
        final int i = _readCursors.indexWhere((EventChatReadCursor c) => c.userId == e.userId);
        final EventChatReadCursor next = EventChatReadCursor(
          userId: e.userId,
          displayName: e.displayName,
          lastReadMessageId: e.lastReadMessageId,
          lastReadMessageCreatedAt: e.lastReadMessageCreatedAt,
        );
        rebuildState(() {
          if (i >= 0) {
            _readCursors[i] = next;
          } else {
            _readCursors.add(next);
          }
        });
      }
    }

    List<String> _seenNamesFor(EventChatMessage m) {
      if (!m.isOwnMessage || m.isDeleted || m.messageType != EventChatMessageType.text) {
        return const <String>[];
      }
      final String? me = _auth?.userId;
      final List<String> result = <String>[];
      for (final EventChatReadCursor c in _readCursors) {
        if (me != null && c.userId == me) {
          continue;
        }
        final DateTime? ref = c.lastReadMessageCreatedAt;
        if (ref == null) {
          continue;
        }
        if (!m.createdAt.toUtc().isAfter(ref.toUtc())) {
          result.add(c.displayName);
        }
      }
      result.sort();
      return result;
    }

    String? _formatSeenLine(List<String> names) {
      if (names.isEmpty) {
        return null;
      }
      const int maxShown = 3;
      if (names.length <= maxShown) {
        return context.l10n.eventChatSeenBy(names.join(', '));
      }
      final String head = names.take(maxShown).join(', ');
      final int more = names.length - maxShown;
      return context.l10n.eventChatSeenByTruncated(head, more);
    }

    bool _allOthersRead(List<String> seenNames) {
      if (seenNames.isEmpty) {
        return false;
      }
      final int others = _participantCount > 0 ? _participantCount - 1 : 0;
      if (others <= 0) {
        return false;
      }
      return seenNames.length >= others;
    }

    void _onComposerTextChanged(String t) {
      if (_searchOpen) {
        return;
      }
      _typingIdle?.cancel();
      final String trim = t.trim();
      if (trim.isEmpty) {
        _typingDebounce?.cancel();
        if (_typingOutboundSent) {
          _typingOutboundSent = false;
          unawaited(_repo.setTyping(widget.eventId, false));
        }
        return;
      }
      _typingDebounce?.cancel();
      _typingDebounce = Timer(const Duration(milliseconds: 300), () {
        if (!mounted || _searchOpen) {
          return;
        }
        if (!_typingOutboundSent) {
          _typingOutboundSent = true;
          unawaited(_repo.setTyping(widget.eventId, true));
        }
      });
      _typingIdle = Timer(const Duration(seconds: 2), () {
        if (!mounted) {
          return;
        }
        if (_typingOutboundSent) {
          _typingOutboundSent = false;
          unawaited(_repo.setTyping(widget.eventId, false));
        }
      });
    }

    void _onComposerSendCompleted() {
      _typingDebounce?.cancel();
      _typingIdle?.cancel();
      if (_typingOutboundSent) {
        _typingOutboundSent = false;
        unawaited(_repo.setTyping(widget.eventId, false));
      }
    }

    /// Active typists sorted by display name (same order as typing label / bubble).
    List<({String userId, String displayName})> _activeTypingPeersSorted(
      BuildContext context,
    ) {
      final DateTime now = DateTime.now();
      final String? me = _auth?.userId;
      final List<({String userId, String displayName})> out =
          <({String userId, String displayName})>[];
      for (final MapEntry<String, EventChatTypingPeer> e in _typingPeers.entries) {
        if (me != null && e.key == me) {
          continue;
        }
        if (now.isAfter(e.value.until)) {
          continue;
        }
        String n = e.value.displayName.trim();
        if (n.isEmpty) {
          n = context.l10n.eventChatTypingUnknownParticipant;
        }
        out.add((userId: e.key, displayName: n));
      }
      out.sort(
        (({String userId, String displayName}) a,
                ({String userId, String displayName}) b) =>
            a.displayName.compareTo(b.displayName),
      );
      return out;
    }

    String? _lastKnownAvatarForUser(String userId) {
      for (int i = _messages.length - 1; i >= 0; i--) {
        final EventChatMessage m = _messages[i];
        if (m.authorId != userId || m.isDeleted) {
          continue;
        }
        final String? u = m.authorAvatarUrl?.trim();
        if (u != null && u.isNotEmpty) {
          return u;
        }
      }
      return null;
    }
}
