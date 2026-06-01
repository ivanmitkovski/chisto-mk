import 'dart:async';

import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:feature_events/src/data/chat/chat_message_list_parse.dart';
import 'package:feature_events/src/data/chat/event_chat_connection_status.dart';
import 'package:feature_events/src/data/chat/event_chat_fetch_result.dart';
import 'package:feature_events/src/data/chat/event_chat_message.dart';
import 'package:feature_events/src/data/chat/event_chat_participants.dart';
import 'package:feature_events/src/data/chat/event_chat_read_cursor.dart';
import 'package:feature_events/src/data/chat/event_chat_repository.dart';
import 'package:feature_events/src/data/chat/event_chat_stream_event.dart';
import 'package:feature_events/src/data/chat/socket_event_chat_stream.dart';
import 'package:feature_notifications/feature_notifications.dart';
import 'package:flutter/foundation.dart';

class ApiEventChatRepository implements EventChatRepository {
  ApiEventChatRepository({
    required ApiClient client,
    required AppConfig config,
    required AuthState authState,
  }) : _client = client,
       _baseUrl = config.apiBaseUrl.replaceFirst(RegExp(r'/$'), ''),
       _authState = authState;

  final ApiClient _client;
  final String _baseUrl;
  final AuthState _authState;

  static const int _maxOpenChatSockets = 6;
  final Map<String, SocketEventChatStream> _wsByEvent =
      <String, SocketEventChatStream>{};
  final List<String> _chatSocketLru = <String>[];
  final Map<String, StreamSubscription<EventChatStreamEvent>> _wsSubs = {};
  final Map<String, StreamController<EventChatStreamEvent>> _chatByEvent = {};

  /// Parse message lists off the UI isolate when history is large.
  static const int _fetchMessagesIsolateThreshold = 80;

  void _touchChatSocketLru(String eventId) {
    _chatSocketLru.remove(eventId);
    _chatSocketLru.add(eventId);
    while (_chatSocketLru.length > _maxOpenChatSockets) {
      final String evict = _chatSocketLru.removeAt(0);
      _stopRealtime(evict);
      final StreamController<EventChatStreamEvent>? ctrl = _chatByEvent.remove(
        evict,
      );
      if (ctrl != null && !ctrl.isClosed) {
        unawaited(ctrl.close());
      }
    }
  }

  SocketEventChatStream _wsStream(String eventId) {
    _touchChatSocketLru(eventId);
    return _wsByEvent.putIfAbsent(eventId, () {
      return SocketEventChatStream(
        baseUrl: _baseUrl,
        authState: _authState,
        sessionRefresh: _client.refreshSessionQueued,
        onAuthRejected: _client.notifySessionAuthRejected,
      );
    });
  }

  StreamController<EventChatStreamEvent> _chatController(String eventId) {
    return _chatByEvent.putIfAbsent(eventId, () {
      late final StreamController<EventChatStreamEvent> ctrl;
      return ctrl = StreamController<EventChatStreamEvent>.broadcast(
        onListen: () {
          _startRealtime(eventId, ctrl);
        },
        onCancel: () {
          final StreamController<EventChatStreamEvent>? c =
              _chatByEvent[eventId];
          if (c != null && !c.hasListener) {
            _stopRealtime(eventId);
            _chatByEvent.remove(eventId);
            unawaited(c.close());
          }
        },
      );
    });
  }

  void _startRealtime(
    String eventId,
    StreamController<EventChatStreamEvent> out,
  ) {
    // [messageStream] and [connectionStatus] both listen to the same broadcast
    // controller; a second onListen must not call [SocketEventChatStream.connect]
    // again or the first socket is disposed and the UI stays on "Reconnecting…".
    final SocketEventChatStream ws = _wsStream(eventId);
    if (_wsSubs.containsKey(eventId)) {
      if (!out.isClosed) {
        out.add(EventChatStreamConnectionChanged(ws.connectionStatus));
      }
      return;
    }
    _wsSubs[eventId] = ws.stream.listen((EventChatStreamEvent e) {
      if (!out.isClosed) {
        out.add(e);
      }
    });
    ws.connect(eventId);
  }

  @override
  EventChatConnectionStatus currentConnectionStatus(String eventId) {
    return _wsByEvent[eventId]?.connectionStatus ??
        EventChatConnectionStatus.disconnected;
  }

  void _stopRealtime(String eventId) {
    _wsSubs[eventId]?.cancel();
    _wsSubs.remove(eventId);
    _wsByEvent[eventId]?.dispose();
    _wsByEvent.remove(eventId);
  }

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
    final List<EventChatMessage> messages =
        rawMaps.length >= _fetchMessagesIsolateThreshold
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
        .map(
          (e) => EventChatMessage.tryFromJson(
            e is Map<String, dynamic> ? e : null,
          ),
        )
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
        .map(
          (e) => EventChatMessage.tryFromJson(
            e is Map<String, dynamic> ? e : null,
          ),
        )
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
      files: files
          .map(
            (UploadableFile f) => MultipartFileData(
              field: 'files',
              bytes: f.bytes,
              fileName: f.fileName,
              mimeType: f.mimeType,
            ),
          )
          .toList(),
      onSendProgress: onSendProgress,
      isCancelled: isCancelled,
    );
    final Map<String, dynamic>? json = res.json;
    final Object? data = json?['data'];
    if (data is! List<dynamic>) {
      throw AppError.validation(message: 'Invalid upload response');
    }
    return data
        .map(EventChatAttachment.tryFromJson)
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
      payload['attachments'] = attachments
          .map((EventChatAttachment a) => a.toJson())
          .toList();
    }
    if (locationLat != null && locationLng != null) {
      payload['location'] = <String, dynamic>{
        'lat': locationLat,
        'lng': locationLng,
        if (locationLabel != null && locationLabel.isNotEmpty)
          'label': locationLabel,
      };
    }
    final ApiResponse res = await _client.post(
      '/events/$eventId/chat',
      body: payload,
    );
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
  Future<EventChatMarkReadResult?> markRead(
    String eventId,
    String? lastReadMessageId,
  ) async {
    final ApiResponse res = await _client.patch(
      '/events/$eventId/chat/read',
      body: lastReadMessageId != null
          ? <String, dynamic>{'lastReadMessageId': lastReadMessageId}
          : <String, dynamic>{},
    );
    return EventChatMarkReadResult.fromResponseJson(res.json);
  }

  @override
  Future<int> fetchUnreadCount(String eventId) async {
    final ApiResponse res = await _client.get(
      '/events/$eventId/chat/unread-count',
    );
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
    final ApiResponse res = await _client.get(
      '/events/$eventId/chat/participants',
    );
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
    final List<EventChatParticipantPreview> participants =
        <EventChatParticipantPreview>[];
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
    return EventChatParticipantsResult(
      count: count,
      participants: participants,
    );
  }

  @override
  Future<List<EventChatReadCursor>> fetchReadCursors(String eventId) async {
    final ApiResponse res = await _client.get(
      '/events/$eventId/chat/read-cursors',
    );
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
  Future<void> setTyping(String eventId, {required bool typing}) async {
    // REST typing is authoritative; WS is best-effort when offline.
    try {
      await _client.post(
        '/events/$eventId/chat/typing',
        body: <String, dynamic>{'typing': typing},
      );
    } on Object catch (_) {
      // Best-effort: notify room over Socket.IO when REST fails (offline / timeout).
      _wsByEvent[eventId]?.emitTyping(eventId, typing: typing);
    }
  }

  @override
  Stream<EventChatStreamEvent> messageStream(String eventId) {
    return _chatController(eventId).stream;
  }

  @override
  Stream<EventChatConnectionStatus> connectionStatus(String eventId) {
    return _chatController(eventId).stream
        .where(
          (EventChatStreamEvent e) => e is EventChatStreamConnectionChanged,
        )
        .map(
          (EventChatStreamEvent e) =>
              (e as EventChatStreamConnectionChanged).status,
        );
  }
}
