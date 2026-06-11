part of 'package:feature_events/src/presentation/screens/event_chat_screen.dart';

extension EventChatTitleBootstrapMixin on _EventChatScreenState {
  Future<void> _resolveEventTitleFromRepository() async {
    final String id = widget.eventId.trim();
    if (!mounted || id.isEmpty) {
      return;
    }
    try {
      final EventsRepository repo = readEventsRepository();
      await repo.prefetchEvent(id);
      if (!mounted) {
        return;
      }
      final String? title = repo.findById(id)?.title.trim();
      if (title == null || title.isEmpty) {
        return;
      }
      rebuildState(() {
        _resolvedEventTitle = title;
      });
    } catch (_) {
      // Keep generic [eventChatTitle] in the AppBar.
    }
  }

  Future<void> _bootstrap() async {
    // Load messages first so the UI is not blocked by participants/mute/cursors.
    // Previously we waited for all four; a slow auxiliary call delayed stream attach and looked like an empty chat until retry.
    await _loadInitial();
    if (!mounted) {
      return;
    }
    if (_loadFailure != null && isTerminalEventChatLoadFailure(_loadFailure!)) {
      return;
    }
    unawaited(
      Future.wait(<Future<void>>[
        _loadMeta(),
        _loadPinned(),
        _loadReadCursors(),
      ]),
    );
    _sse = _repo
        .messageStream(widget.eventId)
        .listen(_onStreamEvent, onError: (_) {});
    _connSub = _repo
        .connectionStatus(widget.eventId)
        .listen(_onConnectionStatus);
    // Do not seed [currentConnectionStatus] while still [disconnected] before the
    // first handshake — that falsely showed "Check your connection" while REST loaded.
    final EventChatConnectionStatus initial = _repo.currentConnectionStatus(
      widget.eventId,
    );
    if (initial == EventChatConnectionStatus.connected ||
        initial == EventChatConnectionStatus.reconnecting) {
      _onConnectionStatus(initial);
    } else {
      rebuildState(() => _conn = initial);
    }
    if (!mounted) {
      return;
    }
    _livePollTimer?.cancel();
    _initialCatchupTimer?.cancel();
    // Close gap between initial REST load and stream subscription.
    _initialCatchupTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted || _loading || _loadFailure != null) {
        return;
      }
      unawaited(_pollLatestMessages());
    });
    _configureLivePollForStatus(_repo.currentConnectionStatus(widget.eventId));
    _attachRealtimeDisruptionListener();
  }

  void _configureLivePollForStatus(EventChatConnectionStatus status) {
    _livePollTimer?.cancel();
    if (!mounted) {
      return;
    }
    final bool streamHealthy = status == EventChatConnectionStatus.connected;
    final Duration interval = streamHealthy
        ? const Duration(seconds: 45)
        : const Duration(milliseconds: 1500);
    _livePollTimer = Timer.periodic(interval, (_) {
      if (!mounted || _loading || _loadFailure != null) {
        return;
      }
      unawaited(_pollLatestMessages());
    });
  }

  Future<void> _pollLatestMessages() async {
    await _mergeLatestFromServer();
    if (mounted) {
      unawaited(_markReadBestEffort());
    }
  }

  Future<void> _loadMeta() async {
    try {
      final bool m = await _repo.fetchMuteStatus(widget.eventId);
      final EventChatParticipantsResult p = await _repo.fetchParticipants(
        widget.eventId,
      );
      if (mounted) {
        rebuildState(() {
          _muted = m;
          _participantCount = p.count;
          _participantPreviews = List<EventChatParticipantPreview>.from(
            p.participants,
          );
          _participantsLoadFailed = false;
        });
      }
    } on Object {
      if (mounted) {
        rebuildState(() => _participantsLoadFailed = true);
      }
    }
  }

  Future<void> _loadPinned() async {
    try {
      final List<EventChatMessage> list = await _repo.fetchPinnedMessages(
        widget.eventId,
      );
      if (mounted) {
        rebuildState(() => _pinned = list);
      }
    } on Object catch (_) {
      logEventsDiagnostic('chat_load_pinned_failed');
    }
  }

  EventChatMessage? get _latestPinned => _pinned.isEmpty ? null : _pinned.first;

  void _onConnectionStatus(EventChatConnectionStatus s) {
    if (!mounted) {
      return;
    }
    _configureLivePollForStatus(s);

    if (s == EventChatConnectionStatus.connected) {
      final bool wasDown =
          _bannerVisible ||
          _repo.realtimeDisruptionVisible(widget.eventId).value;
      if (_sseHadConnected && wasDown) {
        unawaited(
          _mergeLatestFromServer().whenComplete(() {
            if (mounted) {
              unawaited(_pruneOutboxAgainstCommittedMessages());
              unawaited(_flushOfflineQueue());
            }
          }),
        );
      } else {
        unawaited(_flushOfflineQueue());
      }
      _sseHadConnected = true;

      if (wasDown) {
        _bannerVisible = false;
        _flashTimer?.cancel();
        rebuildState(() {
          _showConnectedFlash = true;
          _conn = s;
        });
        _flashTimer = Timer(const Duration(milliseconds: 1200), () {
          if (mounted) {
            rebuildState(() => _showConnectedFlash = false);
          }
        });
      } else {
        rebuildState(() => _conn = s);
      }
      return;
    }

    if (s == EventChatConnectionStatus.disconnected) {
      // Cold start: WS defaults to disconnected until onConnect; REST may already work.
      if (!_sseHadConnected) {
        rebuildState(() => _conn = s);
        return;
      }
      _bannerVisible = true;
      rebuildState(() => _conn = s);
      return;
    }

    // Reconnecting: banner visibility is driven by transport-level debounce.
    if (s == EventChatConnectionStatus.reconnecting) {
      if (!_sseHadConnected) {
        rebuildState(() => _conn = s);
        return;
      }
      rebuildState(() => _conn = s);
    }
  }

  void _attachRealtimeDisruptionListener() {
    if (_disruptionListener != null) {
      return;
    }
    _disruptionListener = () {
      if (mounted) {
        rebuildState(() {});
      }
    };
    _repo
        .realtimeDisruptionVisible(widget.eventId)
        .addListener(_disruptionListener!);
  }
}
