import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:image_picker/image_picker.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/network/connectivity_gate.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/event_chat_haptics.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_theme.dart';
import 'package:chisto_mobile/features/events/data/chat/chat_client_message_id.dart';
import 'package:chisto_mobile/features/events/data/chat/chat_diagnostics.dart';
import 'package:chisto_mobile/features/events/data/chat/chat_upload_limits.dart';
import 'package:chisto_mobile/features/events/data/chat/chat_outbox_sync.dart';
import 'package:chisto_mobile/features/events/data/chat/outbox/chat_outbox_store.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_connection_status.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_fetch_result.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_participants.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_read_cursor.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_repository.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_chat_message_list_order.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_chat_search_merge.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_diagnostic_log.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_attachment_mime.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_attachment_source.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/event_chat_audio_playback_scope.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_stream_event.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_connection_banner.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_date_separator.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_empty_state.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_input_bar.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_message_bubble.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_message_skeleton.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_location_picker_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_pinned_bar.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_participants_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_pinned_messages_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_swipe_reply_wrapper.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_system_message.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_typing_indicator_row.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';

import 'event_chat_screen_widgets.dart';
import 'event_chat_search_panel.dart';

class _GroupingInfo {
  const _GroupingInfo({
    required this.isFirst,
    required this.isLast,
    required this.showDate,
  });

  final bool isFirst;
  final bool isLast;
  final bool showDate;
}

/// Event chat for a cleanup event. Listens to [EventChatRepository.messageStream] for live updates.
///
/// **Realtime smoke (manual):** send a message and confirm live delivery (not poll-only); close
/// and reopen the screen — messages should load without relying on error retry.
class EventChatScreen extends StatefulWidget {
  const EventChatScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.isOrganizer,
    this.repository,
    this.readSyncCompleter,
  });

  final String eventId;
  final String eventTitle;
  final bool isOrganizer;
  final EventChatRepository? repository;

  /// Completed after best-effort read cursor sync on exit (for parent refresh timing).
  final Completer<void>? readSyncCompleter;

  @override
  State<EventChatScreen> createState() => _EventChatScreenState();
}

class _EventChatScreenState extends State<EventChatScreen> with WidgetsBindingObserver {
  EventChatRepository get _repo =>
      widget.repository ?? ServiceLocator.instance.eventChatRepository;

  AuthState? get _auth => ServiceLocator.instance.authStateOrNull;

  final List<EventChatMessage> _messages = <EventChatMessage>[];
  List<_GroupingInfo> _grouping = <_GroupingInfo>[];
  final Map<String, GlobalKey> _bubbleKeys = <String, GlobalKey>{};
  final ScrollController _scroll = ScrollController();
  late final EventChatAudioPlaybackController _audioPlayback;
  StreamSubscription<EventChatStreamEvent>? _sse;
  StreamSubscription<EventChatConnectionStatus>? _connSub;
  StreamSubscription<List<ConnectivityResult>>? _netSub;

  bool _loading = true;
  bool _loadError = false;
  String? _nextOlderCursor;
  bool _hasMoreOlder = false;
  bool _loadingOlder = false;
  bool _showNewPill = false;
  EventChatMessage? _replyTo;
  EventChatMessage? _editing;

  int _participantCount = 0;
  List<EventChatParticipantPreview> _participantPreviews = <EventChatParticipantPreview>[];
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
  Timer? _reconnectDebounce;

  bool _sseHadConnected = false;

  /// False when connectivity reports no usable network (attachments/voice need online upload).
  bool _networkOnline = true;

  List<EventChatReadCursor> _readCursors = <EventChatReadCursor>[];
  final Map<String, EventChatTypingPeer> _typingPeers = <String, EventChatTypingPeer>{};
  Timer? _typingDebounce;
  Timer? _typingIdle;
  Timer? _typingPruneTimer;
  bool _typingOutboundSent = false;

  /// When streams are degraded, polls often; when merged [EventChatConnectionStatus.connected], slow watchdog only.
  Timer? _livePollTimer;
  Timer? _initialCatchupTimer;

  final Map<String, double> _uploadProgressByTempId = <String, double>{};
  final Set<String> _uploadCancelRequested = <String>{};

  @override
  void initState() {
    super.initState();
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
      for (final MapEntry<String, EventChatTypingPeer> e in _typingPeers.entries) {
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
    unawaited(_finalizeReadCursorOnExit().whenComplete(() {
      if (readSync != null && !readSync.isCompleted) {
        readSync.complete();
      }
    }));
    _highlightTimer?.cancel();
    _flashTimer?.cancel();
    _reconnectDebounce?.cancel();
    _searchDebounce?.cancel();
    _typingDebounce?.cancel();
    _typingIdle?.cancel();
    _typingPruneTimer?.cancel();
    _livePollTimer?.cancel();
    _initialCatchupTimer?.cancel();
    if (_typingOutboundSent) {
      _typingOutboundSent = false;
      unawaited(_repo.setTyping(widget.eventId, false));
    }
    _sse?.cancel();
    _connSub?.cancel();
    _netSub?.cancel();
    _searchController.dispose();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _audioPlayback.dispose();
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
    final double bottom = WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom;
    if (bottom > 0 && _nearBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToBottom();
        }
      });
    }
  }

  Future<void> _resolveEventTitleFromRepository() async {
    final String id = widget.eventId.trim();
    if (!mounted || id.isEmpty) {
      return;
    }
    try {
      final EventsRepository repo = ServiceLocator.instance.eventsRepository;
      await repo.prefetchEvent(id);
      if (!mounted) {
        return;
      }
      final String? title = repo.findById(id)?.title.trim();
      if (title == null || title.isEmpty) {
        return;
      }
      setState(() {
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
    unawaited(
      Future.wait(<Future<void>>[
        _loadMeta(),
        _loadPinned(),
        _loadReadCursors(),
      ]),
    );
    _sse = _repo.messageStream(widget.eventId).listen(
      _onStreamEvent,
      onError: (_) {},
    );
    _connSub = _repo.connectionStatus(widget.eventId).listen(_onConnectionStatus);
    if (!mounted) {
      return;
    }
    _livePollTimer?.cancel();
    _initialCatchupTimer?.cancel();
    // Close gap between initial REST load and stream subscription.
    _initialCatchupTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted || _loading || _loadError) {
        return;
      }
      unawaited(_pollLatestMessages());
    });
    // Until we get a merged connection status, assume degraded (fast REST catch-up).
    _configureLivePollForStatus(EventChatConnectionStatus.reconnecting);
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
      if (!mounted || _loading || _loadError) {
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
      final EventChatParticipantsResult p = await _repo.fetchParticipants(widget.eventId);
      if (mounted) {
        setState(() {
          _muted = m;
          _participantCount = p.count;
          _participantPreviews = List<EventChatParticipantPreview>.from(p.participants);
          _participantsLoadFailed = false;
        });
      }
    } on Object {
      if (mounted) {
        setState(() => _participantsLoadFailed = true);
      }
    }
  }

  Future<void> _loadPinned() async {
    try {
      final List<EventChatMessage> list = await _repo.fetchPinnedMessages(widget.eventId);
      if (mounted) {
        setState(() => _pinned = list);
      }
    } on Object catch (_) {
      logEventsDiagnostic('chat_load_pinned_failed');
    }
  }

  EventChatMessage? get _latestPinned =>
      _pinned.isEmpty ? null : _pinned.first;

  void _onConnectionStatus(EventChatConnectionStatus s) {
    if (!mounted) {
      return;
    }
    _configureLivePollForStatus(s);

    if (s == EventChatConnectionStatus.connected) {
      _reconnectDebounce?.cancel();
      _reconnectDebounce = null;

      final bool wasDown = _bannerVisible;
      if (_sseHadConnected && wasDown) {
        unawaited(_mergeLatestFromServer().whenComplete(() {
          if (mounted) {
            unawaited(_pruneOutboxAgainstCommittedMessages());
            unawaited(_flushOfflineQueue());
          }
        }));
      } else {
        unawaited(_flushOfflineQueue());
      }
      _sseHadConnected = true;

      if (wasDown) {
        _bannerVisible = false;
        _flashTimer?.cancel();
        setState(() {
          _showConnectedFlash = true;
          _conn = s;
        });
        _flashTimer = Timer(const Duration(milliseconds: 1200), () {
          if (mounted) {
            setState(() => _showConnectedFlash = false);
          }
        });
      } else {
        setState(() => _conn = s);
      }
      return;
    }

    if (s == EventChatConnectionStatus.disconnected) {
      _reconnectDebounce?.cancel();
      _reconnectDebounce = null;
      _bannerVisible = true;
      setState(() => _conn = s);
      return;
    }

    // Reconnecting: show banner only after a sustained outage (3 s).
    // Transient SSE drops that recover quickly stay invisible.
    if (s == EventChatConnectionStatus.reconnecting) {
      if (_bannerVisible) {
        return;
      }
      _reconnectDebounce ??= Timer(const Duration(seconds: 3), () {
        if (!mounted) {
          return;
        }
        _bannerVisible = true;
        setState(() => _conn = EventChatConnectionStatus.reconnecting);
      });
    }
  }

  Future<void> _mergeLatestFromServer() async {
    try {
      final r = await _repo.fetchMessages(widget.eventId, limit: 20);
      final List<EventChatMessage> incoming =
          List<EventChatMessage>.from(r.messages.reversed);
      if (!mounted) {
        return;
      }
      final Set<String> beforeIds = _messages.map((EventChatMessage m) => m.id).toSet();
      final List<String> newIds = incoming
          .map((EventChatMessage m) => m.id)
          .where((String id) => !beforeIds.contains(id))
          .toList();
      setState(() {
        final Set<String> ids = _messages.map((EventChatMessage m) => m.id).toSet();
        for (final EventChatMessage m in incoming) {
          if (!ids.contains(m.id)) {
            insertEventChatMessageSorted(_messages, m);
            ids.add(m.id);
          }
        }
      });
      if (kDebugMode && newIds.isNotEmpty) {
        final String sample = newIds.take(4).join(', ');
        debugPrint(
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
      final List<EventChatReadCursor> list = await _repo.fetchReadCursors(widget.eventId);
      if (mounted) {
        setState(() => _readCursors = list);
      }
    } on Object catch (_) {
      logEventsDiagnostic('chat_load_read_cursors_failed');
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
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
      setState(() {
        _messages
          ..clear()
          ..addAll(asc);
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
      setState(() {
        _loading = false;
        _loadError = true;
      });
    }
  }

  Future<void> _loadOlder() async {
    if (_loadingOlder || !_hasMoreOlder || _nextOlderCursor == null) {
      return;
    }
    setState(() => _loadingOlder = true);
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
      setState(() {
        _messages.insertAll(0, older);
        _messages.sort(compareEventChatMessagesChronological);
        _nextOlderCursor = result.nextCursor;
        _hasMoreOlder = result.hasMore;
        _loadingOlder = false;
      });
    } on Object catch (_) {
      if (mounted) {
        logEventsDiagnostic('chat_load_older_failed');
        setState(() => _loadingOlder = false);
      }
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) {
      return;
    }
    final ScrollPosition p = _scroll.position;
    // Only load older when the user has scrolled away from the bottom (newest) anchor
    // and is within [threshold] of the top (oldest) edge. A naive
    // "pixels >= maxScrollExtent - threshold" is true at the bottom when max is small
    // (e.g. 0 >= 50 - 120), which spams _loadOlder and breaks tests.
    const double threshold = 120;
    if (p.maxScrollExtent > p.minScrollExtent) {
      final double distFromOldestEdge = p.maxScrollExtent - p.pixels;
      if (distFromOldestEdge <= threshold && p.pixels > p.minScrollExtent + 0.5) {
        unawaited(_loadOlder());
      }
    }
    if (p.pixels <= 80) {
      if (_showNewPill) {
        setState(() => _showNewPill = false);
      }
    }
  }

  bool get _nearBottom {
    if (!_scroll.hasClients) {
      return true;
    }
    return _scroll.position.pixels <= 80;
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scroll.hasClients) {
      return;
    }
    final double target = _scroll.position.minScrollExtent;
    if (animated) {
      _scroll.animateTo(
        target,
        duration: AppMotion.medium,
        curve: AppMotion.smooth,
      );
    } else {
      _scroll.jumpTo(target);
    }
  }

  GlobalKey _keyFor(String id) => _bubbleKeys.putIfAbsent(id, GlobalKey.new);

  void _scrollToMessageId(String id) {
    final GlobalKey? g = _bubbleKeys[id];
    final BuildContext? ctx = g?.currentContext;
    if (ctx != null) {
      AppHaptics.light(context);
      Scrollable.ensureVisible(
        ctx,
        duration: AppMotion.standard,
        curve: AppMotion.smooth,
        alignment: 0.35,
      );
      setState(() => _highlightId = id);
      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted) {
          setState(() => _highlightId = null);
        }
      });
    } else {
      AppSnack.show(context, message: context.l10n.eventChatMessageNotInView);
    }
  }

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
        setState(() => _messages[idx] = m);
      } else {
        // SSE may arrive before the POST response — match the pending
        // optimistic message by author + body (or audio heuristics) to prevent duplicates.
        final int pendingIdx = _matchPendingIndexForIncoming(m);
        if (pendingIdx >= 0) {
          setState(() => _messages[pendingIdx] = m);
        } else {
          setState(() {
            insertEventChatMessageSorted(_messages, m);
          });
          if (_nearBottom) {
            EventChatHaptics.liveMessageDelivered();
            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
          } else {
            setState(() => _showNewPill = true);
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
        setState(() {
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
        setState(() => _messages[idx] = m);
      }
    } else if (e is EventChatStreamMessagePinned) {
      final EventChatMessage m = e.message;
      final int idx = _messages.indexWhere((EventChatMessage x) => x.id == m.id);
      if (idx >= 0) {
        setState(() => _messages[idx] = m);
      }
      unawaited(_loadPinned());
    } else if (e is EventChatStreamMessageUnpinned) {
      final EventChatMessage m = e.message;
      final int idx = _messages.indexWhere((EventChatMessage x) => x.id == m.id);
      if (idx >= 0) {
        setState(() => _messages[idx] = m);
      }
      unawaited(_loadPinned());
    } else if (e is EventChatStreamTypingUpdated) {
      final String? me = _auth?.userId;
      if (me != null && e.userId == me) {
        return;
      }
      setState(() {
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
      setState(() {
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
      await _repo.markRead(widget.eventId, last.id);
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
        await _repo.markRead(widget.eventId, serverNewest.id);
        return;
      }
      if (_messageStrictlyAfter(serverNewest, localLast)) {
        await _repo.markRead(widget.eventId, serverNewest.id);
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
        setState(() {
          final int i = _messages.indexWhere((EventChatMessage m) => m.id == q.tempId);
          if (i >= 0) {
            _messages[i] = saved;
          }
          _dedupMessages();
        });
        unawaited(_markReadBestEffort());
        continue;
      }
      if (res.kind == ChatOutboxFlushKind.terminalFailed) {
        setState(() {
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
    for (final EventChatMessage m in _messages) {
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
      setState(() {});
    }
    unawaited(_flushOfflineQueue());
  }

  /// Rounded-up seconds for display + API (upload does not return duration for audio).
  static int _voiceDurationSeconds(Duration d) {
    if (d <= Duration.zero) {
      return 1;
    }
    final int sec = (d.inMilliseconds + 500) ~/ 1000;
    return sec < 1 ? 1 : sec;
  }

  Future<void> _sendVoiceMessage(XFile file, Duration recordedLength) async {
    if (!_networkOnline) {
      if (!mounted) {
        return;
      }
      AppSnack.show(context, message: context.l10n.eventChatAttachmentsNeedNetwork);
      return;
    }
    final String clientMessageId = newChatClientMessageId();
    final String tempId = 'pending_${DateTime.now().microsecondsSinceEpoch}';
    final int durSec = _voiceDurationSeconds(recordedLength);
    final EventChatAttachment localAtt = EventChatAttachment(
      id: 'local_$tempId',
      url: file.path,
      mimeType: 'audio/m4a',
      fileName: file.name,
      sizeBytes: 0,
      duration: durSec,
    );
    final EventChatMessage optimistic = EventChatMessage(
      id: tempId,
      eventId: widget.eventId,
      authorId: _auth?.userId ?? 'me',
      authorName: _auth?.displayName ?? '…',
      createdAt: DateTime.now().toUtc(),
      body: null,
      isDeleted: false,
      isOwnMessage: true,
      replyToId: _replyTo?.id,
      replyToSnippet: _replyTo?.isDeleted == true ? null : _replyTo?.body,
      pending: true,
      messageType: EventChatMessageType.audio,
      attachments: <EventChatAttachment>[localAtt],
      clientMessageId: clientMessageId,
    );
    setState(() {
      insertEventChatMessageSorted(_messages, optimistic);
      _replyTo = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    EventChatHaptics.attachmentPickerTap(context);
    await _finalizeVoiceSend(tempId, file, recordedLength);
  }

  Future<void> _finalizeVoiceSend(String tempId, XFile file, Duration recordedLength) async {
    void clearUploadTracking() {
      _uploadProgressByTempId.remove(tempId);
      _uploadCancelRequested.remove(tempId);
    }

    try {
      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }
      final String mime = ChatAttachmentMime.infer(file.name, bytes);
      setState(() {
        _uploadProgressByTempId[tempId] = 0.0;
      });
      final List<EventChatAttachment> uploaded = await _repo.uploadAttachments(
        widget.eventId,
        <UploadableFile>[
          UploadableFile(
            bytes: bytes,
            fileName: file.name,
            mimeType: mime,
          ),
        ],
        onSendProgress: (int sent, int total) {
          if (!mounted || total <= 0) {
            return;
          }
          setState(() {
            _uploadProgressByTempId[tempId] = sent / total;
          });
        },
        isCancelled: () => _uploadCancelRequested.contains(tempId),
      );
      if (!mounted) {
        return;
      }
      if (uploaded.isEmpty) {
        setState(() {
          final int i = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
          if (i >= 0) {
            _messages[i] = _messages[i].copyWith(pending: false, failed: true);
          }
          clearUploadTracking();
        });
        AppSnack.show(context, message: context.l10n.eventChatSendFailed);
        return;
      }
      final int voiceSec = _voiceDurationSeconds(recordedLength);
      final EventChatAttachment u = uploaded.first;
      final EventChatAttachment withDuration = EventChatAttachment(
        id: u.id,
        url: u.url,
        mimeType: u.mimeType,
        fileName: u.fileName,
        sizeBytes: u.sizeBytes,
        width: u.width,
        height: u.height,
        duration: u.duration ?? voiceSec,
        thumbnailUrl: u.thumbnailUrl,
      );
      String? replyToId;
      String? clientMessageId;
      final int pendingRow = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
      if (pendingRow >= 0) {
        replyToId = _messages[pendingRow].replyToId;
        clientMessageId = _messages[pendingRow].clientMessageId;
      }
      final EventChatMessage saved = await _repo.sendMessage(
        widget.eventId,
        '',
        replyToId: replyToId,
        attachments: <EventChatAttachment>[withDuration],
        clientMessageId: clientMessageId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        final int i = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
        if (i >= 0) {
          _messages[i] = saved;
        }
        _dedupMessages();
        clearUploadTracking();
      });
      chatDiagLog('voice_send_ok', <String, Object?>{'eventId': widget.eventId});
      unawaited(_markReadBestEffort());
    } on AppError catch (e) {
      if (!mounted) {
        return;
      }
      if (e.code == 'CANCELLED') {
        setState(() {
          _messages.removeWhere((EventChatMessage m) => m.id == tempId);
          clearUploadTracking();
        });
        chatDiagLog('voice_upload_cancelled', <String, Object?>{'eventId': widget.eventId});
        return;
      }
      setState(() {
        final int i = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
        if (i >= 0) {
          _messages[i] = _messages[i].copyWith(pending: false, failed: true);
        }
        clearUploadTracking();
      });
      AppSnack.show(context, message: context.l10n.eventChatSendFailed);
    } on Object catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        final int i = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
        if (i >= 0) {
          _messages[i] = _messages[i].copyWith(pending: false, failed: true);
        }
        clearUploadTracking();
      });
      AppSnack.show(context, message: context.l10n.eventChatSendFailed);
    }
  }

  /// Single video → [video]; all images → [image]; otherwise [file] (mixed gallery + doc).
  EventChatMessageType _messageTypeForAttachmentBatch(List<String> mimesLower) {
    if (mimesLower.isEmpty) {
      return EventChatMessageType.file;
    }
    final bool allImage = mimesLower.every((String m) => m.startsWith('image/'));
    if (allImage) {
      return EventChatMessageType.image;
    }
    if (mimesLower.length == 1) {
      final String m = mimesLower.first;
      if (m.startsWith('video/')) {
        return EventChatMessageType.video;
      }
    }
    return EventChatMessageType.file;
  }

  Future<void> _sendAttachments(List<dynamic> files) async {
    if (!_networkOnline) {
      if (!mounted) {
        return;
      }
      AppSnack.show(context, message: context.l10n.eventChatAttachmentsNeedNetwork);
      return;
    }
    if (files.isEmpty) {
      return;
    }
    final List<XFile> xFiles = <XFile>[];
    for (final dynamic f in files) {
      if (f is XFile) {
        xFiles.add(f);
      }
    }
    if (xFiles.isEmpty) {
      return;
    }
    if (xFiles.length > ChatUploadLimits.maxFilesPerMessage) {
      AppSnack.show(context, message: context.l10n.eventChatSendFailed);
      return;
    }

    final String clientMessageId = newChatClientMessageId();
    final String tempId = 'pending_${DateTime.now().microsecondsSinceEpoch}';
    final List<EventChatAttachment> localAttachments = <EventChatAttachment>[];
    final List<String> mimesLower = <String>[];
    for (int i = 0; i < xFiles.length; i++) {
      final XFile f = xFiles[i];
      final Uint8List bytes = await f.readAsBytes();
      if (!mounted) {
        return;
      }
      final String name = f.name;
      final String mime = ChatAttachmentMime.infer(name, bytes);
      final String ml = mime.toLowerCase();
      if (!ChatUploadLimits.isAllowedMime(ml)) {
        AppSnack.show(context, message: context.l10n.eventChatSendFailed);
        return;
      }
      if (bytes.length > ChatUploadLimits.maxBytesForMime(ml)) {
        AppSnack.show(context, message: context.l10n.eventChatSendFailed);
        return;
      }
      mimesLower.add(ml);
      localAttachments.add(
        EventChatAttachment(
          id: 'local_${tempId}_$i',
          url: f.path,
          mimeType: mime,
          fileName: name,
          sizeBytes: bytes.length,
        ),
      );
    }

    final EventChatMessage optimistic = EventChatMessage(
      id: tempId,
      eventId: widget.eventId,
      authorId: _auth?.userId ?? 'me',
      authorName: _auth?.displayName ?? '…',
      createdAt: DateTime.now().toUtc(),
      body: null,
      isDeleted: false,
      isOwnMessage: true,
      replyToId: _replyTo?.id,
      replyToSnippet: _replyTo?.isDeleted == true ? null : _replyTo?.body,
      pending: true,
      messageType: _messageTypeForAttachmentBatch(mimesLower),
      attachments: localAttachments,
      clientMessageId: clientMessageId,
    );
    setState(() {
      insertEventChatMessageSorted(_messages, optimistic);
      _replyTo = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    if (!mounted) {
      return;
    }
    EventChatHaptics.attachmentPickerTap(context);
    await _finalizeAttachmentSend(tempId, xFiles);
  }

  Future<void> _finalizeAttachmentSend(String tempId, List<XFile> xFiles) async {
    void clearUploadTracking() {
      _uploadProgressByTempId.remove(tempId);
      _uploadCancelRequested.remove(tempId);
    }

    try {
      final List<UploadableFile> uploadable = <UploadableFile>[];
      for (final XFile f in xFiles) {
        final Uint8List bytes = await f.readAsBytes();
        final String name = f.name;
        uploadable.add(
          UploadableFile(
            bytes: bytes,
            fileName: name,
            mimeType: ChatAttachmentMime.infer(name, bytes),
          ),
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _uploadProgressByTempId[tempId] = 0.0;
      });
      final List<EventChatAttachment> uploaded = await _repo.uploadAttachments(
        widget.eventId,
        uploadable,
        onSendProgress: (int sent, int total) {
          if (!mounted || total <= 0) {
            return;
          }
          setState(() {
            _uploadProgressByTempId[tempId] = sent / total;
          });
        },
        isCancelled: () => _uploadCancelRequested.contains(tempId),
      );
      if (!mounted) {
        return;
      }
      if (uploaded.isEmpty) {
        setState(() {
          final int i = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
          if (i >= 0) {
            _messages[i] = _messages[i].copyWith(pending: false, failed: true);
          }
          clearUploadTracking();
        });
        AppSnack.show(context, message: context.l10n.eventChatSendFailed);
        return;
      }
      String? replyToId;
      String? clientMessageId;
      final int pendingRow = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
      if (pendingRow >= 0) {
        replyToId = _messages[pendingRow].replyToId;
        clientMessageId = _messages[pendingRow].clientMessageId;
      }
      final EventChatMessage saved = await _repo.sendMessage(
        widget.eventId,
        '',
        replyToId: replyToId,
        attachments: uploaded,
        clientMessageId: clientMessageId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        final int i = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
        if (i >= 0) {
          _messages[i] = saved;
        }
        _dedupMessages();
        clearUploadTracking();
      });
      chatDiagLog('attachment_send_ok', <String, Object?>{'eventId': widget.eventId});
      unawaited(_markReadBestEffort());
    } on AppError catch (e) {
      if (!mounted) {
        return;
      }
      if (e.code == 'CANCELLED') {
        setState(() {
          _messages.removeWhere((EventChatMessage m) => m.id == tempId);
          clearUploadTracking();
        });
        chatDiagLog('attachment_upload_cancelled', <String, Object?>{'eventId': widget.eventId});
        return;
      }
      setState(() {
        final int i = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
        if (i >= 0) {
          _messages[i] = _messages[i].copyWith(pending: false, failed: true);
        }
        clearUploadTracking();
      });
      AppSnack.show(context, message: context.l10n.eventChatSendFailed);
    } on Object catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        final int i = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
        if (i >= 0) {
          _messages[i] = _messages[i].copyWith(pending: false, failed: true);
        }
        clearUploadTracking();
      });
      AppSnack.show(context, message: context.l10n.eventChatSendFailed);
    }
  }

  Future<void> _openLocationPicker() async {
    if (!_networkOnline) {
      AppSnack.show(context, message: context.l10n.eventChatAttachmentsNeedNetwork);
      return;
    }
    final Map<String, dynamic>? result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      builder: (BuildContext ctx) {
        return const ChatLocationPickerSheet();
      },
    );
    if (result == null || !mounted) return;
    final double? lat = result['lat'] as double?;
    final double? lng = result['lng'] as double?;
    final String? label = result['label'] as String?;
    if (lat == null || lng == null) return;

    final String body = label ?? context.l10n.chatSharedLocation;
    final String clientMessageId = newChatClientMessageId();
    final String tempId = 'pending_${DateTime.now().microsecondsSinceEpoch}';
    final EventChatMessage optimistic = EventChatMessage(
      id: tempId,
      eventId: widget.eventId,
      authorId: _auth?.userId ?? 'me',
      authorName: _auth?.displayName ?? '…',
      createdAt: DateTime.now().toUtc(),
      body: body,
      isDeleted: false,
      isOwnMessage: true,
      pending: true,
      messageType: EventChatMessageType.location,
      locationLat: lat,
      locationLng: lng,
      locationLabel: label,
      clientMessageId: clientMessageId,
    );
    setState(() => insertEventChatMessageSorted(_messages, optimistic));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    EventChatHaptics.attachmentPickerTap(context);
    try {
      final EventChatMessage saved = await _repo.sendMessage(
        widget.eventId,
        body,
        locationLat: lat,
        locationLng: lng,
        locationLabel: label,
        clientMessageId: clientMessageId,
      );
      if (!mounted) return;
      setState(() {
        final int i = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
        if (i >= 0) {
          _messages[i] = saved;
        }
        _dedupMessages();
      });
      unawaited(_markReadBestEffort());
    } on Object catch (_) {
      if (!mounted) return;
      setState(() {
        final int i = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
        if (i >= 0) {
          _messages[i] = _messages[i].copyWith(pending: false, failed: true);
        }
      });
      AppSnack.show(context, message: context.l10n.eventChatSendFailed);
    }
  }

  Future<void> _send(String text) async {
    final String t = text.trim();
    if (t.isEmpty || t.length > 2000) {
      return;
    }
    if (_editing != null) {
      await _submitEdit(t);
      return;
    }
    final String clientMessageId = newChatClientMessageId();
    final String tempId = 'pending_${DateTime.now().microsecondsSinceEpoch}';
    final EventChatMessage optimistic = EventChatMessage(
      id: tempId,
      eventId: widget.eventId,
      authorId: _auth?.userId ?? 'me',
      authorName: _auth?.displayName ?? '…',
      createdAt: DateTime.now().toUtc(),
      body: t,
      isDeleted: false,
      isOwnMessage: true,
      replyToId: _replyTo?.id,
      replyToSnippet: _replyTo?.isDeleted == true
          ? null
          : _replyTo?.body,
      pending: true,
      messageType: EventChatMessageType.text,
      clientMessageId: clientMessageId,
    );
    setState(() {
      insertEventChatMessageSorted(_messages, optimistic);
      _replyTo = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    EventChatHaptics.attachmentPickerTap(context);
    try {
      final EventChatMessage saved = await _repo.sendMessage(
        widget.eventId,
        t,
        replyToId: optimistic.replyToId,
        clientMessageId: clientMessageId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        final int i = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
        if (i >= 0) {
          _messages[i] = saved;
        }
        // SSE may have delivered this message while the POST was in-flight.
        // Remove any duplicate that shares the server ID.
        _dedupMessages();
      });
      unawaited(_markReadBestEffort());
    } on AppError catch (e) {
      if (!mounted) {
        return;
      }
      final String errMsg = e.message;
      String snackMsg = errMsg;
      if (_shouldQueueOffline(e)) {
        final bool queued = await ChatOutboxStore.shared.enqueueText(
          eventId: widget.eventId,
          tempId: tempId,
          clientMessageId: clientMessageId,
          body: t,
          replyToId: optimistic.replyToId,
        );
        if (!mounted) {
          return;
        }
        if (queued) {
          return;
        }
        final bool full = await ChatOutboxStore.shared.isOutboxFullForEvent(widget.eventId);
        if (!mounted) {
          return;
        }
        if (full) {
          snackMsg = context.l10n.eventsChatOutboxFull(ChatOutboxStore.maxPendingTextRowsPerEvent);
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        final int i = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
        if (i >= 0) {
          _messages[i] = _messages[i].copyWith(pending: false, failed: true);
        }
      });
      AppSnack.show(context, message: snackMsg);
    } on Object catch (_) {
      if (!mounted) {
        return;
      }
      final bool queued = await ChatOutboxStore.shared.enqueueText(
        eventId: widget.eventId,
        tempId: tempId,
        clientMessageId: clientMessageId,
        body: t,
        replyToId: optimistic.replyToId,
      );
      if (!mounted) {
        return;
      }
      if (queued) {
        return;
      }
      final bool full = await ChatOutboxStore.shared.isOutboxFullForEvent(widget.eventId);
      if (!mounted) {
        return;
      }
      setState(() {
        final int i = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
        if (i >= 0) {
          _messages[i] = _messages[i].copyWith(pending: false, failed: true);
        }
      });
      if (full) {
        AppSnack.show(
          context,
          message: context.l10n.eventsChatOutboxFull(ChatOutboxStore.maxPendingTextRowsPerEvent),
        );
      }
    }
  }

  Future<void> _submitEdit(String text) async {
    final EventChatMessage? ed = _editing;
    if (ed == null) {
      return;
    }
    final String t = text.trim();
    if (t.isEmpty) {
      return;
    }
    setState(() => _editing = null);
    try {
      final EventChatMessage saved = await _repo.editMessage(widget.eventId, ed.id, t);
      if (!mounted) {
        return;
      }
      setState(() {
        final int i = _messages.indexWhere((EventChatMessage m) => m.id == ed.id);
        if (i >= 0) {
          _messages[i] = saved;
        }
      });
    } on AppError catch (e) {
      if (mounted) {
        setState(() => _editing = ed);
        AppSnack.show(context, message: e.message);
      }
    } on Object catch (_) {
      if (mounted) {
        setState(() => _editing = ed);
        AppSnack.show(context, message: context.l10n.eventChatLoadError);
      }
    }
  }

  Future<void> _retryFailed(EventChatMessage m) async {
    if (!m.failed) {
      return;
    }
    if (m.messageType == EventChatMessageType.audio && m.attachments.length == 1) {
      final String raw = m.attachments.first.url.trim();
      if (raw.startsWith('http://') || raw.startsWith('https://')) {
        return;
      }
      final String path =
          raw.startsWith('file://') ? Uri.parse(raw).toFilePath() : raw;
      final String name =
          m.attachments.first.fileName.isEmpty ? 'voice.m4a' : m.attachments.first.fileName;
      final XFile file = XFile(path, name: name);
      setState(() {
        final int i = _messages.indexWhere((EventChatMessage x) => x.id == m.id);
        if (i >= 0) {
          _messages[i] = m.copyWith(pending: true, failed: false);
        }
      });
      final int sec = m.attachments.first.duration ?? 1;
      await _finalizeVoiceSend(m.id, file, Duration(seconds: sec));
      return;
    }
    if ((m.messageType == EventChatMessageType.image ||
            m.messageType == EventChatMessageType.file ||
            m.messageType == EventChatMessageType.video) &&
        m.attachments.isNotEmpty) {
      final bool allLocal = m.attachments.every(
        (EventChatAttachment a) => !isEventChatRemoteAttachmentUrl(a.url),
      );
      if (!allLocal) {
        return;
      }
      final List<XFile> xFiles = <XFile>[];
      for (final EventChatAttachment a in m.attachments) {
        final String path = eventChatAttachmentFilePath(a.url);
        final String name = a.fileName.isEmpty ? 'attachment' : a.fileName;
        xFiles.add(XFile(path, name: name));
      }
      setState(() {
        final int i = _messages.indexWhere((EventChatMessage x) => x.id == m.id);
        if (i >= 0) {
          _messages[i] = m.copyWith(pending: true, failed: false);
        }
      });
      await _finalizeAttachmentSend(m.id, xFiles);
      return;
    }
    if (m.body == null) {
      return;
    }
    final String t = m.body!;
    setState(() {
      final int i = _messages.indexWhere((EventChatMessage x) => x.id == m.id);
      if (i >= 0) {
        _messages[i] = m.copyWith(pending: true, failed: false);
      }
    });
    try {
      final EventChatMessage saved = await _repo.sendMessage(
        widget.eventId,
        t,
        replyToId: m.replyToId,
        clientMessageId: m.clientMessageId ?? newChatClientMessageId(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        final int i = _messages.indexWhere((EventChatMessage x) => x.id == m.id);
        if (i >= 0) {
          _messages[i] = saved;
        }
      });
    } on Object catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        final int i = _messages.indexWhere((EventChatMessage x) => x.id == m.id);
        if (i >= 0) {
          _messages[i] = _messages[i].copyWith(pending: false, failed: true);
        }
      });
    }
  }

  Future<void> _delete(EventChatMessage m) async {
    try {
      await _repo.deleteMessage(widget.eventId, m.id);
      if (!mounted) {
        return;
      }
      if (_audioPlayback.activeClipKey == m.id) {
        await _audioPlayback.stopActiveClip();
      }
      setState(() {
        final int i = _messages.indexWhere((EventChatMessage x) => x.id == m.id);
        if (i >= 0) {
          _messages[i] = _messages[i].copyWith(
            isDeleted: true,
            body: null,
            isPinned: false,
            attachments: const <EventChatAttachment>[],
            locationLat: null,
            locationLng: null,
            locationLabel: null,
          );
        }
      });
      unawaited(_loadPinned());
    } on Object catch (_) {
      if (mounted) {
        AppSnack.show(context, message: context.l10n.eventChatLoadError);
      }
    }
  }

  Future<void> _togglePin(EventChatMessage m, bool pin) async {
    final int idx = _messages.indexWhere((EventChatMessage x) => x.id == m.id);
    if (idx >= 0) {
      setState(() => _messages[idx] = _messages[idx].copyWith(isPinned: pin));
    }
    try {
      await _repo.setPin(widget.eventId, m.id, pinned: pin);
      if (!mounted) {
        return;
      }
      unawaited(_loadPinned());
      if (!pin) {
        AppSnack.show(context, message: context.l10n.eventChatUnpinConfirm);
      }
    } on AppError catch (e) {
      if (mounted) {
        if (idx >= 0 && idx < _messages.length && _messages[idx].id == m.id) {
          setState(() => _messages[idx] = _messages[idx].copyWith(isPinned: !pin));
        }
        AppSnack.show(context, message: e.message);
      }
    } on Object catch (_) {
      if (mounted) {
        if (idx >= 0 && idx < _messages.length && _messages[idx].id == m.id) {
          setState(() => _messages[idx] = _messages[idx].copyWith(isPinned: !pin));
        }
        AppSnack.show(context, message: context.l10n.eventChatLoadError);
      }
    }
  }

  Future<void> _toggleMute() async {
    if (_muteBusy) {
      return;
    }
    final bool next = !_muted;
    setState(() {
      _muted = next;
      _muteBusy = true;
    });
    try {
      await _repo.setMuteStatus(widget.eventId, next);
      if (mounted) {
        AppSnack.show(
          context,
          message: next ? context.l10n.eventChatMuted : context.l10n.eventChatUnmuted,
        );
      }
    } on Object catch (_) {
      if (mounted) {
        setState(() => _muted = !next);
        AppSnack.show(context, message: context.l10n.eventChatLoadError);
      }
    } finally {
      if (mounted) {
        setState(() => _muteBusy = false);
      }
    }
  }

  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    final String q = text.trim();
    if (q.length < 2) {
      _searchSerial++;
      if (_searchServerHits.isNotEmpty ||
          _searchError ||
          _searchLoading ||
          _lastSearchQuery.isNotEmpty) {
        setState(() {
          _searchServerHits = <EventChatMessage>[];
          _searchCursor = null;
          _searchHasMore = false;
          _searchError = false;
          _searchLoading = false;
          _lastSearchQuery = '';
        });
      }
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_runSearch(q));
    });
  }

  Future<void> _runSearch(String q, {bool loadMore = false}) async {
    final String trimmed = q.trim();
    if (trimmed.length < 2) {
      return;
    }
    if (!loadMore) {
      _searchSerial++;
      final int serial = _searchSerial;
      _lastSearchQuery = trimmed;
      setState(() {
        _searchLoading = true;
        _searchError = false;
        _searchServerHits = <EventChatMessage>[];
        _searchCursor = null;
        _searchHasMore = false;
      });
      await _executeSearchRequest(trimmed, serial, loadMore: false);
    } else {
      if (_lastSearchQuery.length < 2) {
        return;
      }
      setState(() => _searchLoading = true);
      await _executeSearchRequest(_lastSearchQuery.trim(), _searchSerial, loadMore: true);
    }
  }

  Future<void> _executeSearchRequest(
    String trimmed,
    int serial, {
    required bool loadMore,
  }) async {
    try {
      final EventChatFetchResult r = await _repo.searchMessages(
        widget.eventId,
        trimmed,
        limit: 30,
        cursor: loadMore ? _searchCursor : null,
      );
      if (!mounted || _searchSerial != serial) {
        return;
      }
      if (_lastSearchQuery != trimmed) {
        return;
      }
      setState(() {
        _searchError = false;
        if (loadMore) {
          final List<EventChatMessage> next = List<EventChatMessage>.from(_searchServerHits)
            ..addAll(r.messages.reversed);
          _searchServerHits = next;
        } else {
          _searchServerHits = List<EventChatMessage>.from(r.messages.reversed);
        }
        _searchCursor = r.nextCursor;
        _searchHasMore = r.hasMore;
      });
    } on Object catch (_) {
      if (!mounted || _searchSerial != serial) {
        return;
      }
      setState(() {
        _searchError = true;
        if (!loadMore) {
          _searchServerHits = <EventChatMessage>[];
        }
      });
    } finally {
      if (mounted && _searchSerial == serial) {
        setState(() {
          _searchLoading = false;
        });
      }
    }
  }

  List<EventChatMessage> _mergedSearchHits() {
    return mergeEventChatSearchHits(
      serverHits: _searchServerHits,
      allMessages: _messages,
      query: _lastSearchQuery,
    );
  }

  Widget _buildSearchPanel(BuildContext context) {
    final List<EventChatMessage> merged = _mergedSearchHits();
    final bool showLocalBanner = !_searchLoading &&
        _lastSearchQuery.length >= 2 &&
        eventChatSearchMergedIncludesLocalOnly(
          serverHits: _searchServerHits,
          merged: merged,
        );
    return EventChatSearchPanel(
      searchLoading: _searchLoading,
      searchError: _searchError,
      lastSearchQuery: _lastSearchQuery,
      searchHasMore: _searchHasMore,
      merged: merged,
      showLocalBanner: showLocalBanner,
      onRetrySearch: () => _runSearch(_lastSearchQuery),
      onLoadMoreSearch: () => _runSearch(_lastSearchQuery, loadMore: true),
      onSelectHit: (EventChatMessage m) {
        _searchSerial++;
        setState(() {
          _searchOpen = false;
          _searchServerHits = <EventChatMessage>[];
          _searchController.clear();
          _searchDebounce?.cancel();
          _lastSearchQuery = '';
          _searchError = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToMessageId(m.id));
      },
    );
  }

  bool _sameChatGroup(int a, int b) {
    if (a < 0 || b < 0 || a >= _messages.length || b >= _messages.length) {
      return false;
    }
    final EventChatMessage ma = _messages[a];
    final EventChatMessage mb = _messages[b];
    if (ma.messageType == EventChatMessageType.system || mb.messageType == EventChatMessageType.system) {
      return false;
    }
    return ma.authorId == mb.authorId && ma.isOwnMessage == mb.isOwnMessage;
  }

  bool _isFirstInGroup(int i) {
    final EventChatMessage m = _messages[i];
    if (m.messageType == EventChatMessageType.system) {
      return true;
    }
    int p = i - 1;
    while (p >= 0 && _messages[p].messageType == EventChatMessageType.system) {
      p--;
    }
    if (p < 0) {
      return true;
    }
    return !_sameChatGroup(i, p);
  }

  bool _isLastInGroup(int i) {
    final EventChatMessage m = _messages[i];
    if (m.messageType == EventChatMessageType.system) {
      return true;
    }
    int n = i + 1;
    while (n < _messages.length && _messages[n].messageType == EventChatMessageType.system) {
      n++;
    }
    if (n >= _messages.length) {
      return true;
    }
    return !_sameChatGroup(i, n);
  }

  void _rebuildGrouping() {
    final List<_GroupingInfo> g = List<_GroupingInfo>.generate(_messages.length, (int i) {
      final bool first = _isFirstInGroup(i);
      final bool last = _isLastInGroup(i);
      final bool date = i == 0 || !_sameDay(_messages[i].createdAt, _messages[i - 1].createdAt);
      return _GroupingInfo(isFirst: first, isLast: last, showDate: date);
    });
    _grouping = g;
  }

  /// Vertical gap below message at [i] toward the next newer message (Instagram-style: tight in-cluster).
  double _bubbleGapBelowMessageAtIndex(int i) {
    if (i < 0 || i >= _messages.length - 1) {
      return 0;
    }
    final bool newerOpensDay =
        i + 1 < _grouping.length && _grouping[i + 1].showDate;
    if (newerOpensDay) {
      return ChatTheme.bubbleStackGapBetweenClusters;
    }
    return _sameChatGroup(i, i + 1)
        ? ChatTheme.bubbleStackGapWithinCluster
        : ChatTheme.bubbleStackGapBetweenClusters;
  }

  bool _sameDay(DateTime a, DateTime b) {
    final DateTime la = a.toLocal();
    final DateTime lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    if (_searchOpen) {
      // Custom toolbar: Material AppBar + TextField title can lay out under the
      // status bar / Dynamic Island on iOS; explicit top inset matches safe area.
      final double topInset = MediaQuery.paddingOf(context).top;
      return PreferredSize(
        preferredSize: Size.fromHeight(topInset + kToolbarHeight),
        child: Material(
          color: AppColors.appBackground,
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.only(top: topInset),
            child: SizedBox(
              height: kToolbarHeight,
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      _searchDebounce?.cancel();
                      _searchSerial++;
                      setState(() {
                        _searchOpen = false;
                        _searchServerHits = <EventChatMessage>[];
                        _searchController.clear();
                        _lastSearchQuery = '';
                        _searchError = false;
                        _searchLoading = false;
                      });
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: context.l10n.eventChatSearchHint,
                        border: InputBorder.none,
                      ),
                      onChanged: _onSearchChanged,
                      onSubmitted: (String v) => unawaited(_runSearch(v.trim())),
                    ),
                  ),
                  if (_searchLoading)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => unawaited(_runSearch(_searchController.text.trim())),
                      tooltip: context.l10n.eventChatSearchAction,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return AppBar(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: AppColors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.appBackground.withValues(alpha: 0.78),
              border: Border(
                bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.35)),
              ),
            ),
          ),
        ),
      ),
      leading: const AppBackButton(),
      title: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final TextTheme appBarTextTheme = Theme.of(context).textTheme;
          final String effectiveTitle = _resolvedEventTitle.isNotEmpty
              ? _resolvedEventTitle
              : widget.eventTitle;
          final String titleText = effectiveTitle.trim().isEmpty
              ? context.l10n.eventChatTitle
              : effectiveTitle.trim();
          final int count = _participantCount;
          return Semantics(
            button: true,
            label: context.l10n.eventChatParticipantsTitleSemantic(titleText, count),
            child: Material(
              color: AppColors.transparent,
              child: InkWell(
                onTap: () {
                  EventChatHaptics.attachmentPickerTap(context);
                  unawaited(
                    showChatParticipantsSheet(
                      context: context,
                      eventId: widget.eventId,
                      repo: _repo,
                      initialParticipants: List<EventChatParticipantPreview>.from(_participantPreviews),
                      initialCount: _participantCount,
                      currentUserId: _auth?.userId,
                      initialLoadFailed: _participantsLoadFailed && _participantPreviews.isEmpty,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: 44,
                    maxWidth: constraints.maxWidth,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              titleText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.eventsListCardTitle(appBarTextTheme),
                            ),
                            if (count > 0)
                              Text(
                                context.l10n.eventChatParticipantsCount(count),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.eventsChatTimestamp(appBarTextTheme),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: context.l10n.eventChatSearchAction,
          onPressed: () => setState(() => _searchOpen = true),
        ),
        IconButton(
          icon: Icon(_muted ? Icons.notifications_off_outlined : Icons.notifications_outlined),
          tooltip: _muted
              ? context.l10n.eventChatUnmuteNotifications
              : context.l10n.eventChatMuteNotifications,
          onPressed: _muteBusy ? null : () => unawaited(_toggleMute()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _rebuildGrouping();
    final bool reconnecting =
        _networkOnline && _bannerVisible && _conn == EventChatConnectionStatus.reconnecting;
    final bool disconnected =
        _networkOnline && _bannerVisible && _conn == EventChatConnectionStatus.disconnected;
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
                else if (_loadError)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(context.l10n.eventChatLoadError),
                          const SizedBox(height: AppSpacing.md),
                          FilledButton(
                            onPressed: _loadInitial,
                            child: Text(context.l10n.eventsDetailRetryRefresh),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_messages.isEmpty)
                  ChatEmptyState(
                    onSayHello: () {
                      // Focus the composer by triggering a dummy send-cancelled flow
                    },
                  )
                else
                  ScrollConfiguration(
                    behavior: const EventChatScrollBehavior(),
                    child: Semantics(
                      container: true,
                      explicitChildNodes: true,
                      label: context.l10n.eventChatMessagesListSemantics,
                      child: Builder(
                      builder: (BuildContext context) {
                        final List<({String userId, String displayName})> typingPeers =
                            _activeTypingPeersSorted(context);
                        final List<String> typingNames = typingPeers
                            .map((({String userId, String displayName}) p) =>
                                p.displayName)
                            .toList(growable: false);
                        final String? typingPrimaryId =
                            typingPeers.isNotEmpty ? typingPeers.first.userId : null;
                        final String? typingPrimaryAvatar = typingPrimaryId != null
                            ? _lastKnownAvatarForUser(typingPrimaryId)
                            : null;
                        final bool hasTyping = typingNames.isNotEmpty && !_searchOpen;
                        final int extraTop = hasTyping ? 1 : 0;
                        final int extraBottom = _loadingOlder ? 1 : 0;
                        return ListView.builder(
                          controller: _scroll,
                          reverse: true,
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                              return idx == -1 ? null : (_messages.length - 1 - idx);
                            }
                            return null;
                          },
                          itemCount: _messages.length + extraTop + extraBottom,
                          itemBuilder: (BuildContext context, int ri) {
                            if (hasTyping && ri == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: ChatTheme.bubbleStackGapBetweenClusters,
                                ),
                                child: ChatTypingBubble(
                                  displayNames: typingNames,
                                  primaryUserId: typingPrimaryId,
                                  primaryAvatarUrl: typingPrimaryAvatar,
                                ),
                              );
                            }
                            final int adjusted = ri - extraTop;
                            if (_loadingOlder && adjusted == _messages.length) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.md,
                                  AppSpacing.md,
                                  AppSpacing.md,
                                  ChatTheme.bubbleStackGapBetweenClusters,
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              );
                            }
                            final int i = _messages.length - 1 - adjusted;
                        final EventChatMessage m = _messages[i];
                        if (m.messageType == EventChatMessageType.system) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: ri == 0 ? 0 : _bubbleGapBelowMessageAtIndex(i),
                            ),
                            child: ChatSystemMessage(message: m),
                          );
                        }
                        final _GroupingInfo gi = i < _grouping.length
                            ? _grouping[i]
                            : const _GroupingInfo(isFirst: true, isLast: true, showDate: false);
                        final bool showName = !m.isOwnMessage && gi.isFirst;
                        final List<String> seenNames = _seenNamesFor(m);
                        final String? seenLine = _formatSeenLine(seenNames);
                        final bool allRead = _allOthersRead(seenNames);

                        return RepaintBoundary(
                          child: Padding(
                          padding: EdgeInsets.only(
                            bottom: ri == 0 ? 0 : _bubbleGapBelowMessageAtIndex(i),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            key: ValueKey<String>(m.id),
                            children: <Widget>[
                              if (gi.showDate) ChatDateSeparator(date: m.createdAt),
                              ChatSwipeReplyWrapper(
                                enabled: !m.pending && !m.isDeleted,
                                onReply: () => setState(() => _replyTo = m),
                                child: KeyedSubtree(
                                  key: _keyFor(m.id),
                                  child: ChatMessageBubble(
                                message: m,
                                showAuthorName: showName,
                                isFirstInGroup: gi.isFirst,
                                isLastInGroup: gi.isLast,
                                highlighted: _highlightId == m.id,
                                receiptSeenByLine: seenLine,
                                receiptAllPeersRead: allRead,
                                onReply: () => setState(() => _replyTo = m),
                                onReplySnippetTap: m.replyToId != null
                                    ? () => _scrollToMessageId(m.replyToId!)
                                    : null,
                                onDelete: m.isOwnMessage && !m.pending ? () => _delete(m) : null,
                                onRetry: m.failed ? () => _retryFailed(m) : null,
                                onCopy: m.body != null && m.body!.isNotEmpty
                                    ? () {
                                        Clipboard.setData(ClipboardData(text: m.body!));
                                        AppSnack.show(context, message: context.l10n.eventChatCopied);
                                      }
                                    : null,
                                onEdit: m.isOwnMessage &&
                                        !m.pending &&
                                        !m.isDeleted &&
                                        m.messageType == EventChatMessageType.text
                                    ? () => setState(() {
                                          _editing = m;
                                          _replyTo = null;
                                        })
                                    : null,
                                onPin: widget.isOrganizer &&
                                        !m.isDeleted &&
                                        !m.isPinned &&
                                        m.messageType == EventChatMessageType.text
                                    ? () => _togglePin(m, true)
                                    : null,
                                onUnpin: widget.isOrganizer && m.isPinned
                                    ? () => _togglePin(m, false)
                                    : null,
                                uploadFraction: _uploadProgressByTempId[m.id],
                                onCancelUpload: m.pending &&
                                        _uploadProgressByTempId.containsKey(m.id)
                                    ? () => setState(() => _uploadCancelRequested.add(m.id))
                                    : null,
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
                if (_showNewPill && !_loading && !_loadError && !_searchOpen)
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
          if (!_searchOpen)
            ChatInputBar(
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
