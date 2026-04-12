import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_connection_status.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_fetch_result.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_participants.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_read_cursor.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_repository.dart';
import 'package:chisto_mobile/features/events/data/chat/chat_message_list_parse.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_stream_event.dart';
import 'package:chisto_mobile/features/events/data/chat/socket_event_chat_stream.dart';
import 'package:http/http.dart' as http;

/// Merges WebSocket + SSE connection states: connected if either path is up.
class _ConnMergeState {
  EventChatConnectionStatus? ws;
  EventChatConnectionStatus? sse;
  EventChatConnectionStatus? lastMerged;

  EventChatConnectionStatus merged() {
    if (ws == EventChatConnectionStatus.connected ||
        sse == EventChatConnectionStatus.connected) {
      return EventChatConnectionStatus.connected;
    }
    if (ws == EventChatConnectionStatus.disconnected &&
        sse == EventChatConnectionStatus.disconnected) {
      return EventChatConnectionStatus.disconnected;
    }
    return EventChatConnectionStatus.reconnecting;
  }
}

/// Sliding dedupe for duplicate chat events when both SSE and WebSocket deliver the same update.
class _DedupeBuffer {
  final Queue<String> _order = Queue<String>();
  final Set<String> _set = <String>{};
  static const int _max = 250;

  bool remember(String k) {
    if (_set.contains(k)) {
      return false;
    }
    _set.add(k);
    _order.add(k);
    while (_order.length > _max) {
      final String r = _order.removeFirst();
      _set.remove(r);
    }
    return true;
  }
}

class ApiEventChatRepository implements EventChatRepository {
  ApiEventChatRepository({
    required ApiClient client,
    required AppConfig config,
    required AuthState authState,
  })  : _client = client,
        _baseUrl = config.apiBaseUrl.replaceFirst(RegExp(r'/$'), ''),
        _authState = authState;

  final ApiClient _client;
  final String _baseUrl;
  final AuthState _authState;

  final Map<String, SocketEventChatStream> _wsByEvent = <String, SocketEventChatStream>{};
  final Map<String, StreamSubscription<EventChatStreamEvent>> _wsSubs = {};
  final Map<String, StreamController<EventChatStreamEvent>> _chatByEvent = {};
  final Map<String, Future<void>> _loops = {};
  final Map<String, bool> _loopCancelled = {};
  /// Bumped on stop and on each new realtime session so a prior [_runSseLoop] cannot
  /// keep running after leave/re-enter chat (avoids clearing [_loopCancelled] for a stale loop).
  final Map<String, int> _chatLiveSessionGen = <String, int>{};
  final Map<String, _ConnMergeState> _connMerge = <String, _ConnMergeState>{};
  final Map<String, _DedupeBuffer> _dedupeBuffers = <String, _DedupeBuffer>{};

  /// Parse message lists off the UI isolate when history is large.
  static const int _fetchMessagesIsolateThreshold = 80;

  SocketEventChatStream _wsStream(String eventId) {
    return _wsByEvent.putIfAbsent(eventId, () {
      return SocketEventChatStream(
        baseUrl: _baseUrl,
        authState: _authState,
      );
    });
  }

  StreamController<EventChatStreamEvent> _chatController(String eventId) {
    return _chatByEvent.putIfAbsent(eventId, () {
      _loopCancelled[eventId] = false;
      late final StreamController<EventChatStreamEvent> ctrl;
      ctrl = StreamController<EventChatStreamEvent>.broadcast(
        onListen: () {
          _startRealtime(eventId, ctrl);
        },
        onCancel: () {
          final StreamController<EventChatStreamEvent>? c = _chatByEvent[eventId];
          if (c != null && !c.hasListener) {
            _stopRealtime(eventId);
            _loopCancelled[eventId] = true;
            _chatByEvent.remove(eventId);
            _loops.remove(eventId);
          }
        },
      );
      return ctrl;
    });
  }

  // Hot reload can retain broadcast onListen/onCancel closures on old private names.
  void _startWebSocket(String eventId, StreamController<EventChatStreamEvent> out) {
    _startRealtime(eventId, out);
  }

  void _stopWebSocket(String eventId) {
    _stopRealtime(eventId);
  }

  void _startRealtime(String eventId, StreamController<EventChatStreamEvent> out) {
    _loopCancelled[eventId] = false;
    _chatLiveSessionGen[eventId] = (_chatLiveSessionGen[eventId] ?? 0) + 1;
    final int sessionGen = _chatLiveSessionGen[eventId]!;
    _connMerge.putIfAbsent(eventId, _ConnMergeState.new);
    _dedupeBuffers.putIfAbsent(eventId, _DedupeBuffer.new);

    final SocketEventChatStream ws = _wsStream(eventId);
    ws.connect(eventId);
    _wsSubs[eventId]?.cancel();
    _wsSubs[eventId] = ws.stream.listen((EventChatStreamEvent e) {
      if (out.isClosed) {
        return;
      }
      if (e is EventChatStreamConnectionChanged) {
        _updateMergedConnection(eventId, out, ws: e.status);
        return;
      }
      _emitStreamEventDeduped(eventId, out, e, debugTransport: 'ws');
    });

    _loops[eventId] = _runSseLoop(eventId, out, sessionGen);
  }

  void _stopRealtime(String eventId) {
    _loopCancelled[eventId] = true;
    _chatLiveSessionGen[eventId] = (_chatLiveSessionGen[eventId] ?? 0) + 1;
    _wsSubs[eventId]?.cancel();
    _wsSubs.remove(eventId);
    _wsByEvent[eventId]?.dispose();
    _wsByEvent.remove(eventId);
    _connMerge.remove(eventId);
    _dedupeBuffers.remove(eventId);
    _loops.remove(eventId);
  }

  void _updateMergedConnection(
    String eventId,
    StreamController<EventChatStreamEvent> out, {
    EventChatConnectionStatus? ws,
    EventChatConnectionStatus? sse,
  }) {
    if (out.isClosed) {
      return;
    }
    final _ConnMergeState merge = _connMerge.putIfAbsent(eventId, _ConnMergeState.new);
    if (ws != null) {
      merge.ws = ws;
    }
    if (sse != null) {
      merge.sse = sse;
    }
    final EventChatConnectionStatus next = merge.merged();
    if (merge.lastMerged != next) {
      merge.lastMerged = next;
      out.add(EventChatStreamConnectionChanged(next));
    }
  }

  String? _dedupeKeyFor(EventChatStreamEvent e) {
    if (e is EventChatStreamMessageCreated) {
      return 'c:${e.message.id}';
    }
    if (e is EventChatStreamMessageEdited) {
      return 'e:${e.message.id}';
    }
    if (e is EventChatStreamMessagePinned) {
      return 'p:${e.message.id}';
    }
    if (e is EventChatStreamMessageUnpinned) {
      return 'u:${e.message.id}';
    }
    if (e is EventChatStreamMessageDeleted) {
      return 'd:${e.messageId}';
    }
    return null;
  }

  void _emitStreamEventDeduped(
    String eventId,
    StreamController<EventChatStreamEvent> out,
    EventChatStreamEvent e, {
    required String debugTransport,
  }) {
    if (out.isClosed) {
      return;
    }
    final String? key = _dedupeKeyFor(e);
    if (key != null) {
      final _DedupeBuffer buf = _dedupeBuffers.putIfAbsent(eventId, _DedupeBuffer.new);
      if (!buf.remember(key)) {
        if (kDebugMode) {
          debugPrint('[chat:$debugTransport] dedupe drop $key event=$eventId (${e.runtimeType})');
        }
        return;
      }
      if (kDebugMode) {
        debugPrint('[chat:$debugTransport] → UI $key ${e.runtimeType} event=$eventId');
      }
    } else if (kDebugMode) {
      debugPrint('[chat:$debugTransport] → UI ${e.runtimeType} event=$eventId');
    }
    out.add(e);
  }

  EventChatMessage _normalizeMessage(EventChatMessage m) =>
      m.withViewer(_authState.userId);

  @override
  Future<EventChatFetchResult> fetchMessages(
    String eventId, {
    String? cursor,
    int limit = 50,
  }) async {
    final StringBuffer q = StringBuffer('/events/$eventId/chat?limit=$limit');
    if (cursor != null && cursor.isNotEmpty) {
      q.write('&cursor=${Uri.encodeQueryComponent(cursor)}');
    }
    final ApiResponse res = await _client.get(q.toString());
    final Map<String, dynamic>? json = res.json;
    if (json == null) {
      throw AppError.validation(message: 'Invalid chat list response');
    }
    final Object? data = json['data'];
    if (data is! List<dynamic>) {
      throw AppError.validation(message: 'Invalid chat list payload');
    }
    final String? uid = _authState.userId;
    final List<Map<String, dynamic>> rawMaps = <Map<String, dynamic>>[];
    for (final Object? e in data) {
      if (e is Map<String, dynamic>) {
        rawMaps.add(e);
      } else if (e is Map) {
        rawMaps.add(Map<String, dynamic>.from(e));
      }
    }
    final List<EventChatMessage> messages = rawMaps.length >= _fetchMessagesIsolateThreshold
        ? await compute(
            parseEventChatMessageBatch,
            ChatMessageListParseArg(rawMaps: rawMaps, viewerUserId: uid),
          )
        : rawMaps
            .map(EventChatMessage.tryFromJson)
            .whereType<EventChatMessage>()
            .map((EventChatMessage m) => m.withViewer(uid))
            .toList();
    final Object? meta = json['meta'];
    bool hasMore = false;
    String? nextCursor;
    if (meta is Map<String, dynamic>) {
      hasMore = meta['hasMore'] == true;
      final Object? nc = meta['nextCursor'];
      if (nc is String && nc.isNotEmpty) {
        nextCursor = nc;
      }
    }
    return EventChatFetchResult(
      messages: messages,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
  }

  @override
  Future<EventChatFetchResult> searchMessages(
    String eventId,
    String query, {
    String? cursor,
    int limit = 20,
  }) async {
    final StringBuffer q = StringBuffer(
      '/events/$eventId/chat/search?limit=$limit&q=${Uri.encodeQueryComponent(query)}',
    );
    if (cursor != null && cursor.isNotEmpty) {
      q.write('&cursor=${Uri.encodeQueryComponent(cursor)}');
    }
    final ApiResponse res = await _client.get(q.toString());
    final Map<String, dynamic>? json = res.json;
    if (json == null) {
      throw AppError.validation(message: 'Invalid chat search response');
    }
    final Object? data = json['data'];
    if (data is! List<dynamic>) {
      throw AppError.validation(message: 'Invalid chat search payload');
    }
    final String? uid = _authState.userId;
    final List<EventChatMessage> messages = data
        .map((e) => EventChatMessage.tryFromJson(e is Map<String, dynamic> ? e : null))
        .whereType<EventChatMessage>()
        .map((EventChatMessage m) => m.withViewer(uid))
        .toList();
    final Object? meta = json['meta'];
    bool hasMore = false;
    String? nextCursor;
    if (meta is Map<String, dynamic>) {
      hasMore = meta['hasMore'] == true;
      final Object? nc = meta['nextCursor'];
      if (nc is String && nc.isNotEmpty) {
        nextCursor = nc;
      }
    }
    return EventChatFetchResult(
      messages: messages,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
  }

  @override
  Future<List<EventChatMessage>> fetchPinnedMessages(String eventId) async {
    final ApiResponse res = await _client.get('/events/$eventId/chat/pinned');
    final Map<String, dynamic>? json = res.json;
    if (json == null) {
      throw AppError.validation(message: 'Invalid pinned response');
    }
    final Object? data = json['data'];
    if (data is! List<dynamic>) {
      throw AppError.validation(message: 'Invalid pinned payload');
    }
    final String? uid = _authState.userId;
    return data
        .map((e) => EventChatMessage.tryFromJson(e is Map<String, dynamic> ? e : null))
        .whereType<EventChatMessage>()
        .map((EventChatMessage m) => m.withViewer(uid))
        .toList();
  }

  @override
  Future<List<EventChatAttachment>> uploadAttachments(
    String eventId,
    List<UploadableFile> files, {
    void Function(int sent, int total)? onSendProgress,
    bool Function()? isCancelled,
  }) async {
    final ApiResponse res = await _client.multipartPost(
      '/events/$eventId/chat/upload',
      files: files.map((UploadableFile f) => MultipartFileData(
        field: 'files',
        bytes: f.bytes,
        fileName: f.fileName,
        mimeType: f.mimeType,
      )).toList(),
      onSendProgress: onSendProgress,
      isCancelled: isCancelled,
    );
    final Map<String, dynamic>? json = res.json;
    final Object? data = json?['data'];
    if (data is! List<dynamic>) {
      throw AppError.validation(message: 'Invalid upload response');
    }
    return data
        .map((Object? e) => EventChatAttachment.tryFromJson(e))
        .whereType<EventChatAttachment>()
        .toList();
  }

  @override
  Future<EventChatMessage> sendMessage(
    String eventId,
    String body, {
    String? replyToId,
    List<EventChatAttachment>? attachments,
    double? locationLat,
    double? locationLng,
    String? locationLabel,
    String? clientMessageId,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{'body': body};
    if (clientMessageId != null && clientMessageId.isNotEmpty) {
      payload['clientMessageId'] = clientMessageId;
    }
    if (replyToId != null && replyToId.isNotEmpty) {
      payload['replyToId'] = replyToId;
    }
    if (attachments != null && attachments.isNotEmpty) {
      payload['attachments'] = attachments.map((EventChatAttachment a) => a.toJson()).toList();
    }
    if (locationLat != null && locationLng != null) {
      payload['location'] = <String, dynamic>{
        'lat': locationLat,
        'lng': locationLng,
        if (locationLabel != null) 'label': locationLabel,
      };
    }
    final ApiResponse res = await _client.post('/events/$eventId/chat', body: payload);
    final Map<String, dynamic>? json = res.json;
    if (json == null) {
      throw AppError.validation(message: 'Invalid chat send response');
    }
    final Object? data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw AppError.validation(message: 'Invalid chat message payload');
    }
    final EventChatMessage? msg = EventChatMessage.tryFromJson(data);
    if (msg == null) {
      throw AppError.validation(message: 'Could not parse sent message');
    }
    return msg.withViewer(_authState.userId);
  }

  @override
  Future<EventChatMessage> editMessage(
    String eventId,
    String messageId,
    String body,
  ) async {
    final ApiResponse res = await _client.patch(
      '/events/$eventId/chat/$messageId',
      body: <String, dynamic>{'body': body},
    );
    final Map<String, dynamic>? json = res.json;
    if (json == null) {
      throw AppError.validation(message: 'Invalid chat edit response');
    }
    final Object? data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw AppError.validation(message: 'Invalid chat message payload');
    }
    final EventChatMessage? msg = EventChatMessage.tryFromJson(data);
    if (msg == null) {
      throw AppError.validation(message: 'Could not parse edited message');
    }
    return msg.withViewer(_authState.userId);
  }

  @override
  Future<EventChatMessage> setPin(
    String eventId,
    String messageId, {
    required bool pinned,
  }) async {
    final ApiResponse res = await _client.post(
      '/events/$eventId/chat/$messageId/pin',
      body: <String, dynamic>{'pinned': pinned},
    );
    final Map<String, dynamic>? json = res.json;
    if (json == null) {
      throw AppError.validation(message: 'Invalid pin response');
    }
    final Object? data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw AppError.validation(message: 'Invalid chat message payload');
    }
    final EventChatMessage? msg = EventChatMessage.tryFromJson(data);
    if (msg == null) {
      throw AppError.validation(message: 'Could not parse pinned message');
    }
    return msg.withViewer(_authState.userId);
  }

  @override
  Future<void> deleteMessage(String eventId, String messageId) async {
    await _client.delete('/events/$eventId/chat/$messageId');
  }

  @override
  Future<void> markRead(String eventId, String? lastReadMessageId) async {
    await _client.patch(
      '/events/$eventId/chat/read',
      body: lastReadMessageId != null
          ? <String, dynamic>{'lastReadMessageId': lastReadMessageId}
          : <String, dynamic>{},
    );
  }

  @override
  Future<int> fetchUnreadCount(String eventId) async {
    final ApiResponse res = await _client.get('/events/$eventId/chat/unread-count');
    final Map<String, dynamic>? json = res.json;
    if (json == null) {
      throw AppError.validation(message: 'Invalid unread response');
    }
    final Object? data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw AppError.validation(message: 'Invalid unread payload');
    }
    final Object? count = data['count'];
    if (count is int) {
      return count;
    }
    if (count is num) {
      return count.toInt();
    }
    return 0;
  }

  @override
  Future<bool> fetchMuteStatus(String eventId) async {
    final ApiResponse res = await _client.get('/events/$eventId/chat/mute');
    final Map<String, dynamic>? json = res.json;
    if (json == null) {
      throw AppError.validation(message: 'Invalid mute response');
    }
    final Object? data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw AppError.validation(message: 'Invalid mute payload');
    }
    return data['muted'] == true;
  }

  @override
  Future<void> setMuteStatus(String eventId, bool muted) async {
    await _client.put(
      '/events/$eventId/chat/mute',
      body: <String, dynamic>{'muted': muted},
    );
  }

  @override
  Future<EventChatParticipantsResult> fetchParticipants(String eventId) async {
    final ApiResponse res = await _client.get('/events/$eventId/chat/participants');
    final Map<String, dynamic>? json = res.json;
    if (json == null) {
      throw AppError.validation(message: 'Invalid participants response');
    }
    final Object? data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw AppError.validation(message: 'Invalid participants payload');
    }
    final Object? countRaw = data['count'];
    final int count = countRaw is int
        ? countRaw
        : countRaw is num
            ? countRaw.toInt()
            : 0;
    final Object? list = data['participants'];
    final List<EventChatParticipantPreview> participants = <EventChatParticipantPreview>[];
    if (list is List<dynamic>) {
      for (final Object? e in list) {
        if (e is Map<String, dynamic>) {
          final Object? id = e['id'];
          final Object? dn = e['displayName'];
          if (id is String && dn is String) {
            participants.add(
              EventChatParticipantPreview(
                id: id,
                displayName: dn,
                avatarUrl: e['avatarUrl'] as String?,
              ),
            );
          }
        }
      }
    }
    return EventChatParticipantsResult(count: count, participants: participants);
  }

  @override
  Future<List<EventChatReadCursor>> fetchReadCursors(String eventId) async {
    final ApiResponse res = await _client.get('/events/$eventId/chat/read-cursors');
    final Map<String, dynamic>? json = res.json;
    if (json == null) {
      throw AppError.validation(message: 'Invalid read-cursors response');
    }
    final Object? data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw AppError.validation(message: 'Invalid read-cursors payload');
    }
    final Object? list = data['cursors'];
    final List<EventChatReadCursor> out = <EventChatReadCursor>[];
    if (list is List<dynamic>) {
      for (final Object? e in list) {
        if (e is Map<String, dynamic>) {
          final EventChatReadCursor? c = EventChatReadCursor.tryFromJson(e);
          if (c != null) {
            out.add(c);
          }
        }
      }
    }
    return out;
  }

  @override
  Future<void> setTyping(String eventId, bool typing) async {
    // Always use REST so typing reaches SSE subscribers and Redis fan-out.
    // WS-only emit skipped peers who only consume SSE and dropped events if the socket was not connected.
    try {
      await _client.post(
        '/events/$eventId/chat/typing',
        body: <String, dynamic>{'typing': typing},
      );
    } on Object catch (_) {
      // Best-effort: notify room over Socket.IO when REST fails (offline / timeout).
      _wsByEvent[eventId]?.emitTyping(eventId, typing);
    }
  }

  @override
  Stream<EventChatStreamEvent> messageStream(String eventId) {
    return _chatController(eventId).stream;
  }

  @override
  Stream<EventChatConnectionStatus> connectionStatus(String eventId) {
    return _chatController(eventId).stream.where((EventChatStreamEvent e) => e is EventChatStreamConnectionChanged).map(
          (EventChatStreamEvent e) => (e as EventChatStreamConnectionChanged).status,
        );
  }

  Future<void> _runSseLoop(
    String eventId,
    StreamController<EventChatStreamEvent> out,
    int sessionGen,
  ) async {
    http.Client? sseClient;
    String? lastStreamEventId;
    int attempt = 0;
    bool firstConnect = true;

    bool sessionAlive() =>
        _loopCancelled[eventId] != true &&
        !out.isClosed &&
        (_chatLiveSessionGen[eventId] ?? 0) == sessionGen;

    void emitConn(EventChatConnectionStatus s) {
      _updateMergedConnection(eventId, out, sse: s);
    }

    while (sessionAlive()) {
      if (!_authState.isAuthenticated) {
        if (!firstConnect) {
          emitConn(EventChatConnectionStatus.reconnecting);
        }
        await Future<void>.delayed(const Duration(seconds: 1));
        if (!sessionAlive()) {
          break;
        }
        continue;
      }
      final String? token = _authState.accessToken;
      if (token == null || token.isEmpty) {
        if (!firstConnect) {
          emitConn(EventChatConnectionStatus.reconnecting);
        }
        await Future<void>.delayed(const Duration(seconds: 1));
        if (!sessionAlive()) {
          break;
        }
        continue;
      }
      if (!firstConnect && attempt > 0) {
        emitConn(EventChatConnectionStatus.reconnecting);
      }
      sseClient?.close();
      final http.Client liveClient = http.Client();
      sseClient = liveClient;
      try {
        await _connectSseOnce(
          eventId: eventId,
          token: token,
          client: liveClient,
          controller: out,
          lastStreamEventId: lastStreamEventId,
          logStreamOpenedDebug: firstConnect,
          emitConnectionStatus: emitConn,
          emitChatEvent: (EventChatStreamEvent evt) =>
              _emitStreamEventDeduped(eventId, out, evt, debugTransport: 'sse'),
          onStreamEventId: (String id) {
            lastStreamEventId = id;
          },
        );
        // Stream ended gracefully (server closed / keepalive timeout).
        // Reset attempt counter and reconnect — this is NOT an error, so we must NOT emit reconnecting.
        attempt = 0;
        firstConnect = false;
        if (!sessionAlive()) {
          break;
        }
        // Avoid tight reconnect loops (ALB/proxy closes, log spam, request storms).
        await Future<void>.delayed(const Duration(milliseconds: 750));
        if (!sessionAlive()) {
          break;
        }
        continue;
      } on AppError catch (e) {
        if (e.code == 'UNAUTHORIZED') {
          emitConn(EventChatConnectionStatus.disconnected);
          return;
        }
      } on Object catch (_) {
        // reconnect with backoff
      }
      if (!sessionAlive()) {
        break;
      }
      attempt += 1;
      await Future<void>.delayed(_nextBackoff(attempt));
    }
  }

  Duration _nextBackoff(int a) {
    final int capped = a.clamp(1, 8);
    final int baseMs = 500 * (1 << (capped - 1));
    const int maxMs = 30 * 1000;
    final int ms = math.min(baseMs, maxMs);
    final int jitterMs = (ms * 0.2).round();
    final int random =
        DateTime.now().microsecondsSinceEpoch % ((jitterMs * 2) + 1);
    final int withJitter = ms - jitterMs + random;
    return Duration(milliseconds: withJitter.clamp(300, maxMs));
  }

  Future<void> _connectSseOnce({
    required String eventId,
    required String token,
    required http.Client client,
    required StreamController<EventChatStreamEvent> controller,
    required String? lastStreamEventId,
    required bool logStreamOpenedDebug,
    required void Function(EventChatConnectionStatus status) emitConnectionStatus,
    required void Function(EventChatStreamEvent evt) emitChatEvent,
    required void Function(String id) onStreamEventId,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/events/$eventId/chat/events');
    final http.Request req = http.Request('GET', uri);
    req.headers['Accept'] = 'text/event-stream';
    req.headers['Cache-Control'] = 'no-cache';
    req.headers['Authorization'] = 'Bearer $token';
    if (lastStreamEventId != null && lastStreamEventId.isNotEmpty) {
      req.headers['Last-Event-ID'] = lastStreamEventId;
    }

    final http.StreamedResponse res = await client.send(req).timeout(
      const Duration(seconds: 45),
      onTimeout: () => throw TimeoutException('Chat SSE connect'),
    );
    if (res.statusCode == 401) {
      _authState.setUnauthenticated();
      emitConnectionStatus(EventChatConnectionStatus.disconnected);
      throw AppError.unauthorized();
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      if (kDebugMode) {
        debugPrint(
          '[chat:sse] connect failed event=$eventId status=${res.statusCode}',
        );
      }
      throw AppError.network(message: 'Chat SSE failed: ${res.statusCode}');
    }

    if (kDebugMode && logStreamOpenedDebug) {
      debugPrint('[chat:sse] stream opened event=$eventId');
    }
    emitConnectionStatus(EventChatConnectionStatus.connected);

    final Stream<String> lines =
        res.stream.transform(utf8.decoder).transform(const LineSplitter());
    final StringBuffer data = StringBuffer();
    String? currentEventId;

    Future<void> dispatch() async {
      if (data.isEmpty) {
        currentEventId = null;
        return;
      }
      final String raw = data.toString();
      data.clear();
      Object? decoded;
      try {
        decoded = jsonDecode(raw);
      } on Object catch (_) {
        currentEventId = null;
        return;
      }
      if (decoded is! Map<String, dynamic>) {
        currentEventId = null;
        return;
      }
      final String? type = decoded['type'] as String?;
      if (type == 'heartbeat') {
        currentEventId = null;
        return;
      }
      if (currentEventId != null && currentEventId!.isNotEmpty) {
        onStreamEventId(currentEventId!);
      }
      if (type == 'message_created') {
        final Object? msg = decoded['message'];
        if (msg is Map<String, dynamic>) {
          final EventChatMessage? m = EventChatMessage.tryFromJson(msg);
          if (m != null) {
            emitChatEvent(EventChatStreamMessageCreated(_normalizeMessage(m)));
          }
        }
      } else if (type == 'message_deleted') {
        final String? mid = decoded['messageId'] as String?;
        if (mid != null && mid.isNotEmpty) {
          emitChatEvent(EventChatStreamMessageDeleted(mid));
        }
      } else if (type == 'message_edited') {
        final Object? msg = decoded['message'];
        if (msg is Map<String, dynamic>) {
          final EventChatMessage? m = EventChatMessage.tryFromJson(msg);
          if (m != null) {
            emitChatEvent(EventChatStreamMessageEdited(_normalizeMessage(m)));
          }
        }
      } else if (type == 'message_pinned') {
        final Object? msg = decoded['message'];
        if (msg is Map<String, dynamic>) {
          final EventChatMessage? m = EventChatMessage.tryFromJson(msg);
          if (m != null) {
            emitChatEvent(EventChatStreamMessagePinned(_normalizeMessage(m)));
          }
        }
      } else if (type == 'message_unpinned') {
        final Object? msg = decoded['message'];
        if (msg is Map<String, dynamic>) {
          final EventChatMessage? m = EventChatMessage.tryFromJson(msg);
          if (m != null) {
            emitChatEvent(EventChatStreamMessageUnpinned(_normalizeMessage(m)));
          }
        }
      } else if (type == 'typing_update') {
        final Object? uid = decoded['userId'];
        final Object? dn = decoded['displayName'];
        final Object? ty = decoded['typing'];
        if (uid is String && ty is bool) {
          final String name = dn is String ? dn.trim() : '';
          emitChatEvent(
            EventChatStreamTypingUpdated(
              eventId: eventId,
              userId: uid,
              displayName: name,
              typing: ty,
            ),
          );
        }
      } else if (type == 'read_cursor_updated') {
        final Object? uid = decoded['userId'];
        final Object? dn = decoded['displayName'];
        final Object? lid = decoded['lastReadMessageId'];
        final Object? lca = decoded['lastReadMessageCreatedAt'];
        if (uid is String && dn is String) {
          DateTime? at;
          if (lca is String && lca.isNotEmpty) {
            at = DateTime.tryParse(lca);
          }
          emitChatEvent(
            EventChatStreamReadCursorUpdated(
              eventId: eventId,
              userId: uid,
              displayName: dn,
              lastReadMessageId: lid is String ? lid : null,
              lastReadMessageCreatedAt: at,
            ),
          );
        }
      }
      currentEventId = null;
    }

    await for (final String line in lines) {
      if (controller.isClosed) {
        return;
      }
      if (line.isEmpty) {
        await dispatch();
        continue;
      }
      if (line.startsWith(':')) {
        continue;
      }
      final int idx = line.indexOf(':');
      final String field = idx == -1 ? line : line.substring(0, idx);
      String value = idx == -1 ? '' : line.substring(idx + 1);
      if (value.startsWith(' ')) {
        value = value.substring(1);
      }
      if (field == 'data') {
        if (data.isNotEmpty) {
          data.writeln();
        }
        data.write(value);
      } else if (field == 'id') {
        currentEventId = value;
      }
    }
  }
}
