part of 'package:feature_events/src/presentation/screens/event_chat_screen.dart';

class _EventChatScreenState extends ConsumerState<EventChatScreen>
    with WidgetsBindingObserver, StateRebuildMixin {
  /// Resolved in [initState] so [dispose] never reads [ref] after unmount.
  late final EventChatRepository _chatRepository;

  EventChatRepository get _repo => _chatRepository;

  AuthState get _auth => ref.read(authStateProvider);

  final List<EventChatMessage> _messages = <EventChatMessage>[];
  List<EventChatMessageGroupingInfo> _grouping =
      <EventChatMessageGroupingInfo>[];
  final Map<String, GlobalKey> _bubbleKeys = <String, GlobalKey>{};
  final ScrollController _scroll = ScrollController();
  late final EventChatAudioPlaybackController _audioPlayback;
  StreamSubscription<EventChatStreamEvent>? _sse;
  StreamSubscription<EventChatConnectionStatus>? _connSub;
  StreamSubscription<List<ConnectivityResult>>? _netSub;

  bool _loading = true;
  AppError? _loadFailure;
  String? _nextOlderCursor;
  bool _hasMoreOlder = false;
  bool _loadingOlder = false;
  bool _showNewPill = false;
  EventChatMessage? _replyTo;
  EventChatMessage? _editing;

  int _participantCount = 0;
  List<EventChatParticipantPreview> _participantPreviews =
      <EventChatParticipantPreview>[];
  bool _participantsLoadFailed = false;
  List<EventChatMessage> _pinned = <EventChatMessage>[];
  bool _muted = false;
  bool _muteBusy = false;

  bool _searchOpen = false;
  final TextEditingController _searchController = TextEditingController();

  /// Last successful HTTP search page(s); merged with [_messages] for display.
  List<EventChatMessage> _searchServerHits = <EventChatMessage>[];
  bool _searchLoading = false;
  bool _searchError = false;
  int _searchSerial = 0;
  String? _searchCursor;
  bool _searchHasMore = false;
  Timer? _searchDebounce;
  String _lastSearchQuery = '';

  String? _highlightId;
  Timer? _highlightTimer;

  /// Filled from [EventChatScreen.eventTitle] or after [EventsRepository.prefetchEvent] when title was missing (e.g. push notification).
  String _resolvedEventTitle = '';

  EventChatConnectionStatus? _conn;
  bool _bannerVisible = false;
  bool _showConnectedFlash = false;
  Timer? _flashTimer;
  VoidCallback? _disruptionListener;

  bool _sseHadConnected = false;

  /// False when connectivity reports no usable network (attachments/voice need online upload).
  bool _networkOnline = true;

  List<EventChatReadCursor> _readCursors = <EventChatReadCursor>[];
  final Map<String, EventChatTypingPeer> _typingPeers =
      <String, EventChatTypingPeer>{};
  Timer? _typingDebounce;
  Timer? _typingIdle;
  Timer? _typingPruneTimer;
  bool _typingOutboundSent = false;

  /// When streams are degraded, polls often; when merged [EventChatConnectionStatus.connected], slow watchdog only.
  Timer? _livePollTimer;
  Timer? _initialCatchupTimer;

  final Map<String, double> _uploadProgressByTempId = <String, double>{};
  final Set<String> _uploadCancelRequested = <String>{};
  final FocusNode _composerFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _chatRepository =
        widget.repository ?? ref.read(eventChatRepositoryProvider);
    EventChatForegroundScope.instance.setActiveEventId(widget.eventId);
    _resolvedEventTitle = widget.eventTitle.trim();
    if (_resolvedEventTitle.isEmpty && widget.eventId.trim().isNotEmpty) {
      unawaited(_resolveEventTitleFromRepository());
    }
    _audioPlayback = EventChatAudioPlaybackController();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
    unawaited(_bootstrap());
    _typingPruneTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      final DateTime now = DateTime.now();
      final List<String> remove = <String>[];
      for (final MapEntry<String, EventChatTypingPeer> e
          in _typingPeers.entries) {
        if (now.isAfter(e.value.until)) {
          remove.add(e.key);
        }
      }
      if (remove.isEmpty) {
        return;
      }
      setState(() {
        for (final String k in remove) {
          _typingPeers.remove(k);
        }
      });
    });
    unawaited(
      ConnectivityGate.check().then((List<ConnectivityResult> r) {
        if (!mounted) {
          return;
        }
        setState(() {
          _networkOnline = ConnectivityGate.isOnline(r);
        });
      }),
    );
    _netSub = ConnectivityGate.watch().listen((List<ConnectivityResult> r) {
      if (!mounted) {
        return;
      }
      setState(() {
        _networkOnline = ConnectivityGate.isOnline(r);
      });
      if (ConnectivityGate.isOnline(r)) {
        unawaited(_flushOfflineQueue());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final Completer<void>? readSync = widget.readSyncCompleter;
    unawaited(
      _finalizeReadCursorOnExit().whenComplete(() {
        if (readSync != null && !readSync.isCompleted) {
          readSync.complete();
        }
      }),
    );
    _highlightTimer?.cancel();
    _flashTimer?.cancel();
    _searchDebounce?.cancel();
    _typingDebounce?.cancel();
    _typingIdle?.cancel();
    _typingPruneTimer?.cancel();
    _livePollTimer?.cancel();
    _initialCatchupTimer?.cancel();
    if (_typingOutboundSent) {
      _typingOutboundSent = false;
      unawaited(_repo.setTyping(widget.eventId, typing: false));
    }
    _sse?.cancel();
    _connSub?.cancel();
    _netSub?.cancel();
    final VoidCallback? disruptionListener = _disruptionListener;
    if (disruptionListener != null) {
      _repo
          .realtimeDisruptionVisible(widget.eventId)
          .removeListener(disruptionListener);
      _disruptionListener = null;
    }
    _searchController.dispose();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _composerFocus.dispose();
    _audioPlayback.dispose();
    if (EventChatForegroundScope.instance.activeEventId == widget.eventId) {
      EventChatForegroundScope.instance.setActiveEventId(null);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      unawaited(_markReadBestEffort());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_pollLatestMessages());
    }
  }

  @override
  void didChangeMetrics() {
    final double bottom = WidgetsBinding
        .instance
        .platformDispatcher
        .views
        .first
        .viewInsets
        .bottom;
    if (bottom > 0 && _nearBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToBottom();
        }
      });
    }
  }

  Widget _buildLoadFailureBody(BuildContext context) {
    final AppError failure = _loadFailure!;
    if (isEventNoLongerAvailable(failure)) {
      return const EventDetailNotFoundView();
    }
    if (isEventChatAccessDenied(failure)) {
      return AppErrorView(error: failure);
    }
    return AppErrorView(
      error: failure,
      onRetry: _loadInitial,
      retryFootnote: context.l10n.eventChatLoadError,
    );
  }

  @override
  Widget build(BuildContext context) {
    _rebuildGrouping();
    final bool reconnecting =
        _networkOnline &&
        _sseHadConnected &&
        _conn == EventChatConnectionStatus.reconnecting &&
        _repo.realtimeDisruptionVisible(widget.eventId).value;
    final bool disconnected =
        _networkOnline &&
        _bannerVisible &&
        _conn == EventChatConnectionStatus.disconnected;
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: ChatTheme.surfaceCanvas(colorScheme),
      // Search field lives in the app bar; resizing the body for the keyboard
      // would compress the message list with no focused field in the body.
      resizeToAvoidBottomInset: !_searchOpen,
      appBar: _buildAppBar(context),
      body: EventChatAudioPlaybackScope(
        controller: _audioPlayback,
        child: Column(
          children: <Widget>[
            ChatConnectionBanner(
              networkOffline: !_networkOnline,
              reconnecting: reconnecting,
              disconnected: disconnected,
              showConnectedFlash: _showConnectedFlash,
              reduceMotion: reduceMotion,
            ),
            ChatPinnedBar(
              latest: _latestPinned,
              pinnedCount: _pinned.length,
              isOrganizer: widget.isOrganizer,
              onUnpinLatest: _latestPinned != null
                  ? () => _togglePin(_latestPinned!, false)
                  : null,
              onOpenAll: () {
                showChatPinnedMessagesSheet(
                  context: context,
                  pinned: _pinned,
                  isOrganizer: widget.isOrganizer,
                  onUnpin: (EventChatMessage m) => _togglePin(m, false),
                  onSelect: (EventChatMessage m) => _scrollToMessageId(m.id),
                );
              },
              onTapMessage: (EventChatMessage m) => _scrollToMessageId(m.id),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      ChatTheme.surfaceCanvas(colorScheme),
                      ChatTheme.surfaceCanvasElevated(colorScheme),
                    ],
                  ),
                ),
                child: Stack(
                  children: <Widget>[
                    if (_searchOpen)
                      _buildSearchPanel(context)
                    else if (_loading)
                      const ChatMessageSkeletonList()
                    else if (_loadFailure != null)
                      _buildLoadFailureBody(context)
                    else if (_messages.isEmpty)
                      ChatEmptyState(onSayHello: _composerFocus.requestFocus)
                    else
                      ScrollConfiguration(
                        behavior: const EventChatScrollBehavior(),
                        child: Semantics(
                          container: true,
                          explicitChildNodes: true,
                          label: context.l10n.eventChatMessagesListSemantics,
                          child: Builder(
                            builder: (BuildContext context) {
                              final List<({String userId, String displayName})>
                              typingPeers = _activeTypingPeersSorted(context);
                              final List<String> typingNames = typingPeers
                                  .map(
                                    (({String userId, String displayName}) p) =>
                                        p.displayName,
                                  )
                                  .toList(growable: false);
                              final String? typingPrimaryId =
                                  typingPeers.isNotEmpty
                                  ? typingPeers.first.userId
                                  : null;
                              final String? typingPrimaryAvatar =
                                  typingPrimaryId != null
                                  ? _lastKnownAvatarForUser(typingPrimaryId)
                                  : null;
                              final bool hasTyping =
                                  typingNames.isNotEmpty && !_searchOpen;
                              final int extraTop = hasTyping ? 1 : 0;
                              final int extraBottom = _loadingOlder ? 1 : 0;
                              return ListView.builder(
                                controller: _scroll,
                                reverse: true,
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                cacheExtent: 1400,
                                addAutomaticKeepAlives: false,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.md,
                                ),
                                findChildIndexCallback: (Key key) {
                                  if (key is ValueKey<String>) {
                                    final int idx = _messages.indexWhere(
                                      (EventChatMessage m) => m.id == key.value,
                                    );
                                    return idx == -1
                                        ? null
                                        : (_messages.length - 1 - idx);
                                  }
                                  return null;
                                },
                                itemCount:
                                    _messages.length + extraTop + extraBottom,
                                itemBuilder: (BuildContext context, int ri) {
                                  if (hasTyping && ri == 0) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: ChatTheme
                                            .bubbleStackGapBetweenClusters,
                                      ),
                                      child: ChatTypingBubble(
                                        displayNames: typingNames,
                                        primaryUserId: typingPrimaryId,
                                        primaryAvatarUrl: typingPrimaryAvatar,
                                      ),
                                    );
                                  }
                                  final int adjusted = ri - extraTop;
                                  if (_loadingOlder &&
                                      adjusted == _messages.length) {
                                    return const Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        AppSpacing.md,
                                        AppSpacing.md,
                                        AppSpacing.md,
                                        ChatTheme.bubbleStackGapBetweenClusters,
                                      ),
                                      child: Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: AppLoadingIndicator(
                                            size: AppLoadingIndicatorSize.sm,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  final int i = _messages.length - 1 - adjusted;
                                  final EventChatMessage m = _messages[i];
                                  if (m.messageType ==
                                      EventChatMessageType.system) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: ri == 0
                                            ? 0
                                            : eventChatBubbleGapBelow(
                                                messages: _messages,
                                                grouping: _grouping,
                                                i: i,
                                              ),
                                      ),
                                      child: ChatSystemMessage(message: m),
                                    );
                                  }
                                  final EventChatMessageGroupingInfo gi =
                                      i < _grouping.length
                                      ? _grouping[i]
                                      : const EventChatMessageGroupingInfo(
                                          isFirst: true,
                                          isLast: true,
                                          showDate: false,
                                        );
                                  final bool showName =
                                      !m.isOwnMessage && gi.isFirst;
                                  final List<String> seenNames = _seenNamesFor(
                                    m,
                                  );
                                  final String? seenLine = _formatSeenLine(
                                    seenNames,
                                  );
                                  final bool allRead = _allOthersRead(
                                    seenNames,
                                  );

                                  return RepaintBoundary(
                                    key: ValueKey<String>(
                                      'chat-bubble-${m.id}',
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        bottom: ri == 0
                                            ? 0
                                            : eventChatBubbleGapBelow(
                                                messages: _messages,
                                                grouping: _grouping,
                                                i: i,
                                              ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        key: ValueKey<String>(m.id),
                                        children: <Widget>[
                                          if (gi.showDate)
                                            ChatDateSeparator(
                                              date: m.createdAt,
                                            ),
                                          ChatSwipeReplyWrapper(
                                            enabled: !m.pending && !m.isDeleted,
                                            onReply: () =>
                                                setState(() => _replyTo = m),
                                            child: KeyedSubtree(
                                              key: _isCanonicalBubbleIndex(i)
                                                  ? _keyFor(m.id)
                                                  : null,
                                              child: ChatMessageBubble(
                                                message: m,
                                                showAuthorName: showName,
                                                isFirstInGroup: gi.isFirst,
                                                isLastInGroup: gi.isLast,
                                                highlighted:
                                                    _highlightId == m.id,
                                                receiptSeenByLine: seenLine,
                                                receiptAllPeersRead: allRead,
                                                onReply: () => setState(
                                                  () => _replyTo = m,
                                                ),
                                                onReplySnippetTap:
                                                    m.replyToId != null
                                                    ? () => _scrollToMessageId(
                                                        m.replyToId!,
                                                      )
                                                    : null,
                                                onDelete:
                                                    m.isOwnMessage && !m.pending
                                                    ? () => _delete(m)
                                                    : null,
                                                onRetry: m.failed
                                                    ? () => _retryFailed(m)
                                                    : null,
                                                onCopy:
                                                    m.body != null &&
                                                        m.body!.isNotEmpty
                                                    ? () {
                                                        Clipboard.setData(
                                                          ClipboardData(
                                                            text: m.body!,
                                                          ),
                                                        );
                                                        AppSnack.show(
                                                          context,
                                                          message: context
                                                              .l10n
                                                              .eventChatCopied,
                                                        );
                                                      }
                                                    : null,
                                                onEdit:
                                                    m.isOwnMessage &&
                                                        !m.pending &&
                                                        !m.isDeleted &&
                                                        m.messageType ==
                                                            EventChatMessageType
                                                                .text
                                                    ? () => setState(() {
                                                        _editing = m;
                                                        _replyTo = null;
                                                      })
                                                    : null,
                                                onPin:
                                                    widget.isOrganizer &&
                                                        !m.isDeleted &&
                                                        !m.isPinned &&
                                                        m.messageType ==
                                                            EventChatMessageType
                                                                .text
                                                    ? () => _togglePin(m, true)
                                                    : null,
                                                onUnpin:
                                                    widget.isOrganizer &&
                                                        m.isPinned
                                                    ? () => _togglePin(m, false)
                                                    : null,
                                                uploadFraction:
                                                    _uploadProgressByTempId[m
                                                        .id],
                                                onCancelUpload:
                                                    m.pending &&
                                                        _uploadProgressByTempId
                                                            .containsKey(m.id)
                                                    ? () => setState(
                                                        () =>
                                                            _uploadCancelRequested
                                                                .add(m.id),
                                                      )
                                                    : null,
                                                onAuthorBlocked:
                                                    _removeMessagesByAuthorId,
                                                downloadRemoteAttachment: ref
                                                    .read(
                                                      eventChatAttachmentDownloaderProvider,
                                                    )
                                                    .downloadRemoteAttachment,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    if (_showNewPill &&
                        !_loading &&
                        _loadFailure == null &&
                        !_searchOpen)
                      Positioned(
                        bottom: AppSpacing.md,
                        right: AppSpacing.md,
                        child: EventChatScrollToBottomFab(
                          onTap: () {
                            setState(() => _showNewPill = false);
                            _scrollToBottom();
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (!_searchOpen && _loadFailure == null)
              ChatInputBar(
                composerFocusNode: _composerFocus,
                replyTo: _replyTo,
                onCancelReply: () => setState(() => _replyTo = null),
                editingMessage: _editing,
                onCancelEdit: () => setState(() => _editing = null),
                onSend: _send,
                onSendImages: _sendAttachments,
                onSendVoice: _sendVoiceMessage,
                onShareLocation: _openLocationPicker,
                onComposerTextChanged: _onComposerTextChanged,
                onComposerSendCompleted: _onComposerSendCompleted,
                attachmentsNeedNetwork: !_networkOnline,
              ),
          ],
        ),
      ),
    );
  }
}
