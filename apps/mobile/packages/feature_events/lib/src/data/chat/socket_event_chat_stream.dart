import 'dart:async';

import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/network/realtime_disruption_signal.dart';
import 'package:chisto_infrastructure/core/network/realtime_socket_options.dart';
import 'package:chisto_infrastructure/core/network/realtime_socket_transport_policy.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_events/src/data/chat/event_chat_connection_status.dart';
import 'package:feature_events/src/data/chat/event_chat_message.dart';
import 'package:feature_events/src/data/chat/event_chat_stream_event.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

@visibleForTesting
bool chatSocketNeedsReconnectForNewToken({
  required bool socketConnected,
  required String? newAccessToken,
  required String? tokenAtHandshake,
}) {
  return socketConnected &&
      newAccessToken != null &&
      newAccessToken.isNotEmpty &&
      newAccessToken != tokenAtHandshake;
}

/// Manages a Socket.IO connection to the `/chat` namespace (sole realtime transport).
class SocketEventChatStream {
  SocketEventChatStream({
    required String baseUrl,
    required AuthState authState,
    Future<RefreshOutcome> Function()? sessionRefresh,
    void Function()? onAuthRejected,
    RealtimeSocketTransportPolicy? transportPolicy,
    RealtimeDisruptionSignal? disruptionSignal,
  }) : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
       _authState = authState,
       _sessionRefresh = sessionRefresh,
       _onAuthRejected = onAuthRejected,
       _transportPolicy = transportPolicy ?? RealtimeSocketTransportPolicy() {
    _disruption =
        disruptionSignal ??
        RealtimeDisruptionSignal(
          channel: 'chat',
          resolveHost: () => Uri.tryParse(_baseUrl)?.host ?? _baseUrl,
          resolveTransports: _transportPolicy.describeTransports,
        );
  }

  final String _baseUrl;
  final AuthState _authState;
  final Future<RefreshOutcome> Function()? _sessionRefresh;
  final void Function()? _onAuthRejected;
  final RealtimeSocketTransportPolicy _transportPolicy;
  late final RealtimeDisruptionSignal _disruption;

  sio.Socket? _socket;
  String? _currentEventId;
  bool _authListenerAttached = false;
  bool _refreshInFlight = false;
  String? _tokenAtHandshake;
  String? _lastStreamEventId;
  final StreamController<EventChatStreamEvent> _controller =
      StreamController<EventChatStreamEvent>.broadcast();

  Stream<EventChatStreamEvent> get stream => _controller.stream;

  EventChatConnectionStatus _lastStatus =
      EventChatConnectionStatus.disconnected;

  EventChatConnectionStatus get connectionStatus => _lastStatus;

  ValueNotifier<bool> get disruptionVisible => _disruption.visible;

  String get _debugHost => Uri.tryParse(_baseUrl)?.host ?? _baseUrl;

  void _syncDisruptionForStatus(EventChatConnectionStatus status) {
    switch (status) {
      case EventChatConnectionStatus.connected:
        _disruption.setLive(isLive: true);
      case EventChatConnectionStatus.disconnected:
        _disruption.setLive(isLive: true);
        _disruption.visible.value = false;
      case EventChatConnectionStatus.reconnecting:
        _disruption.setLive(isLive: false);
    }
  }

  void connect(String eventId) {
    _currentEventId = eventId;
    final sio.Socket? existing = _socket;
    if (existing != null && existing.connected) {
      scheduleMicrotask(_emitJoin);
      _replayCurrentStatus();
      return;
    }
    _disconnectSocketOnly();
    _ensureAuthListener();

    final String? token = _authState.accessToken;
    if (token == null || token.isEmpty) return;

    _emitStatus(EventChatConnectionStatus.reconnecting);

    final String origin = '$_baseUrl/chat';
    final String debugHost = _debugHost;
    final List<String> transports = _transportPolicy.currentTransports();

    AppLog.verbose(
      '[chat:ws] connect host=$debugHost event=$eventId transports=${transports.join(",")}',
    );

    _socket = sio.io(
      origin,
      RealtimeSocketOptions.build(
        transportPolicy: _transportPolicy,
        authSubmit: RealtimeSocketOptions.tokenAuthSubmit(
          () => _authState.accessToken,
        ),
      ).build(),
    );

    _socket!
      ..onConnect((_) {
        AppLog.verbose('[chat:ws] connect host=$debugHost event=$eventId');
        _transportPolicy.recordConnectSuccess();
        _tokenAtHandshake = _authState.accessToken;
        _emitStatus(EventChatConnectionStatus.connected);
        scheduleMicrotask(_emitJoin);
      })
      ..onReconnect((_) {
        _transportPolicy.recordConnectSuccess();
        _tokenAtHandshake = _authState.accessToken;
        _emitStatus(EventChatConnectionStatus.connected);
        scheduleMicrotask(_emitJoin);
      })
      ..onReconnectAttempt((_) {
        AppLog.verbose(
          '[chat:ws] reconnectAttempt host=$debugHost event=$eventId',
        );
        _emitStatus(EventChatConnectionStatus.reconnecting);
      })
      ..onConnectError((dynamic data) {
        AppLog.verbose(
          '[chat:ws] connect_error host=$debugHost event=$eventId type=${data.runtimeType}',
        );
        _handleHandshakeFailure(eventId);
      })
      ..onReconnectError((dynamic data) {
        AppLog.verbose(
          '[chat:ws] reconnect_error host=$debugHost event=$eventId type=${data.runtimeType}',
        );
      })
      ..onDisconnect((_) {
        AppLog.verbose('[chat:ws] disconnect host=$debugHost event=$eventId');
        _emitStatus(EventChatConnectionStatus.reconnecting);
      })
      ..onError((dynamic err) {
        AppLog.verbose(
          '[chat:ws] engine error host=$debugHost event=$eventId type=${err.runtimeType}',
        );
        _handleHandshakeFailure(eventId);
      })
      ..on('error', (dynamic data) {
        if (data is Map && data['code'] == 'AUTH_FAILED') {
          unawaited(_onAuthFailed(eventId));
        }
      })
      ..on('sync', (dynamic data) {
        final Map<String, dynamic>? map = _asStringKeyedMap(
          _unwrapSocketArgs(data),
        );
        if (map == null) return;
        final Object? events = map['events'];
        if (events is! List) return;
        for (final Object? item in events) {
          if (item is Map) {
            _dispatchBusPayload(eventId, Map<String, dynamic>.from(item));
          }
        }
      })
      ..on('message:created', (dynamic data) => _onSocketPayload(eventId, data))
      ..on('message:deleted', (dynamic data) => _onSocketPayload(eventId, data))
      ..on('message:edited', (dynamic data) => _onSocketPayload(eventId, data))
      ..on('message:pinned', (dynamic data) => _onSocketPayload(eventId, data))
      ..on(
        'message:unpinned',
        (dynamic data) => _onSocketPayload(eventId, data),
      )
      ..on('typing:update', (dynamic data) => _onSocketPayload(eventId, data))
      ..on(
        'read_cursor:updated',
        (dynamic data) => _onSocketPayload(eventId, data),
      );

    _socket!.connect();
  }

  void _handleHandshakeFailure(String eventId) {
    if (_socket?.connected ?? false) {
      return;
    }
    _emitStatus(EventChatConnectionStatus.reconnecting);
    if (_transportPolicy.recordConnectFailure()) {
      AppLog.warn(
        '[chat:ws] falling back to polling+websocket host=$_debugHost event=$eventId',
        category: 'realtime',
      );
      _disconnectSocketOnly();
      connect(eventId);
    }
  }

  Future<void> _onAuthFailed(String eventId) async {
    if (_refreshInFlight) return;
    _disconnectSocketOnly();
    final Future<RefreshOutcome> Function()? refresh = _sessionRefresh;
    if (refresh == null) {
      _emitStatus(EventChatConnectionStatus.disconnected);
      return;
    }
    _refreshInFlight = true;
    try {
      final RefreshOutcome outcome = await refresh();
      if (_controller.isClosed) return;
      if (!_authState.isAuthenticated) return;
      _applyAuthRefreshOutcome(eventId, outcome);
    } catch (_) {
      if (!_controller.isClosed) {
        _emitStatus(EventChatConnectionStatus.reconnecting);
      }
    } finally {
      _refreshInFlight = false;
    }
  }

  void _applyAuthRefreshOutcome(String eventId, RefreshOutcome outcome) {
    switch (outcome) {
      case RefreshOutcome.success:
        connect(eventId);
      case RefreshOutcome.serverRejected:
        _onAuthRejected?.call();
      case RefreshOutcome.transient:
        _emitStatus(EventChatConnectionStatus.reconnecting);
    }
  }

  void emitTyping(String eventId, {required bool typing}) {
    _socket?.emit('typing', <String, dynamic>{
      'eventId': eventId,
      'typing': typing,
    });
  }

  void disconnect() => _disconnectSocketOnly();

  void _ensureAuthListener() {
    if (_authListenerAttached) {
      return;
    }
    _authState.addListener(_onAuthStateChanged);
    _authListenerAttached = true;
  }

  void _onAuthStateChanged() {
    if (_controller.isClosed) {
      return;
    }
    final String? eventId = _currentEventId;
    final String? token = _authState.accessToken;
    if (eventId == null || eventId.isEmpty) {
      return;
    }
    if (token == null || token.isEmpty) {
      _disconnectSocketOnly();
      _emitStatus(EventChatConnectionStatus.disconnected);
      return;
    }
    final sio.Socket? sock = _socket;
    final bool connected = sock != null && sock.connected;
    if (chatSocketNeedsReconnectForNewToken(
      socketConnected: connected,
      newAccessToken: token,
      tokenAtHandshake: _tokenAtHandshake,
    )) {
      connect(eventId);
    }
  }

  /// Drops the Engine.IO socket but keeps room intent and auth listener (for token-driven reconnect).
  void _disconnectSocketOnly() {
    if (_socket != null) {
      if (_currentEventId != null) {
        _socket!.emit('leave', <String, String>{'eventId': _currentEventId!});
      }
      _socket!.dispose();
      _socket = null;
    }
    _tokenAtHandshake = null;
  }

  void dispose() {
    if (_authListenerAttached) {
      _authState.removeListener(_onAuthStateChanged);
      _authListenerAttached = false;
    }
    if (_socket != null) {
      if (_currentEventId != null) {
        _socket!.emit('leave', <String, String>{'eventId': _currentEventId!});
      }
      _socket!.dispose();
      _socket = null;
    }
    _tokenAtHandshake = null;
    _transportPolicy.reset();
    _currentEventId = null;
    _disruption.dispose();
    _controller.close();
  }

  /// Best-effort key list for debug when [EventChatMessage.tryFromJson] rejects a payload.
  static String _debugPayloadKeys(dynamic raw) {
    final Map<String, dynamic>? map = _asStringKeyedMapStatic(raw);
    if (map == null) {
      return 'type=${raw.runtimeType}';
    }
    final Object? inner = map['message'];
    final Map<String, dynamic>? msgMap = _asStringKeyedMapStatic(inner);
    if (msgMap != null) {
      return 'wrapper=${map.keys.join(",")} messageKeys=${msgMap.keys.join(",")}';
    }
    return map.keys.join(',');
  }

  static Map<String, dynamic>? _asStringKeyedMapStatic(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((Object? k, Object? v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  /// Socket.IO may deliver a single payload as a one-element list.
  dynamic _unwrapSocketArgs(dynamic data) {
    if (data is List && data.length == 1) {
      return data.first;
    }
    return data;
  }

  EventChatMessage? _parseMessage(dynamic data) {
    final Map<String, dynamic>? map = _asStringKeyedMap(data);
    if (map == null) return null;
    final Object? msg = map['message'];
    final Map<String, dynamic>? messageMap = _asStringKeyedMap(msg);
    if (messageMap != null) {
      return EventChatMessage.tryFromJson(messageMap);
    }
    return EventChatMessage.tryFromJson(map);
  }

  /// JSON from Socket.IO is often `Map<dynamic, dynamic>`; normalize for parsing.
  Map<String, dynamic>? _asStringKeyedMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((Object? k, Object? v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  void _emitJoin() {
    final String? eventId = _currentEventId;
    final sio.Socket? s = _socket;
    if (eventId == null || eventId.isEmpty || s == null) {
      return;
    }
    final Map<String, String> payload = <String, String>{'eventId': eventId};
    final String? last = _lastStreamEventId;
    if (last != null && last.isNotEmpty) {
      payload['lastStreamEventId'] = last;
    }
    s.emit('join', payload);
  }

  void _onSocketPayload(String eventId, dynamic data) {
    final dynamic raw = _unwrapSocketArgs(data);
    if (!_payloadRoomMatches(raw)) {
      return;
    }
    final Map<String, dynamic>? map = _asStringKeyedMap(raw);
    if (map == null) {
      return;
    }
    _dispatchBusPayload(eventId, map);
  }

  void _dispatchBusPayload(String eventId, Map<String, dynamic> decoded) {
    _noteStreamEventId(decoded);
    final String? type = decoded['type'] as String?;
    if (type == null || type.isEmpty) {
      return;
    }
    switch (type) {
      case 'message_created':
        final EventChatMessage? m = _parseMessage(decoded);
        if (m != null && _messageRoomMatches(m)) {
          _addEvent(
            EventChatStreamMessageCreated(m.withViewer(_authState.userId)),
          );
        } else if (m == null) {
          AppLog.verbose(
            '[chat:ws] message_created parse failed event=$eventId keys=${_debugPayloadKeys(decoded)}',
          );
        }
      case 'message_deleted':
        final String? mid = decoded['messageId'] as String?;
        if (mid != null && mid.isNotEmpty) {
          _addEvent(EventChatStreamMessageDeleted(mid));
        }
      case 'message_edited':
        final EventChatMessage? m = _parseMessage(decoded);
        if (m != null && _messageRoomMatches(m)) {
          _addEvent(
            EventChatStreamMessageEdited(m.withViewer(_authState.userId)),
          );
        }
      case 'message_pinned':
        final EventChatMessage? m = _parseMessage(decoded);
        if (m != null && _messageRoomMatches(m)) {
          _addEvent(
            EventChatStreamMessagePinned(m.withViewer(_authState.userId)),
          );
        }
      case 'message_unpinned':
        final EventChatMessage? m = _parseMessage(decoded);
        if (m != null && _messageRoomMatches(m)) {
          _addEvent(
            EventChatStreamMessageUnpinned(m.withViewer(_authState.userId)),
          );
        }
      case 'typing_update':
        _dispatchTyping(eventId, decoded);
      case 'read_cursor_updated':
        _dispatchReadCursor(eventId, decoded);
      default:
        break;
    }
  }

  void _noteStreamEventId(Map<String, dynamic> decoded) {
    final String? id = decoded['streamEventId'] as String?;
    if (id != null && id.isNotEmpty) {
      _lastStreamEventId = id;
    }
  }

  void _dispatchTyping(String eventId, Map<String, dynamic> map) {
    final Object? pe = map['eventId'];
    if (pe is String &&
        pe.isNotEmpty &&
        (_currentEventId == null || pe != _currentEventId)) {
      return;
    }
    final String? uid = map['userId'] as String?;
    final String? dn = map['displayName'] as String?;
    final bool? ty = map['typing'] as bool?;
    if (uid != null && ty != null) {
      final String name = (dn != null && dn.trim().isNotEmpty) ? dn.trim() : '';
      _addEvent(
        EventChatStreamTypingUpdated(
          eventId: eventId,
          userId: uid,
          displayName: name,
          typing: ty,
        ),
      );
    }
  }

  void _dispatchReadCursor(String eventId, Map<String, dynamic> map) {
    final Object? pe = map['eventId'];
    if (pe is String &&
        pe.isNotEmpty &&
        (_currentEventId == null || pe != _currentEventId)) {
      return;
    }
    final String? uid = map['userId'] as String?;
    final String? dn = map['displayName'] as String?;
    if (uid != null && dn != null) {
      DateTime? at;
      final String? lca = map['lastReadMessageCreatedAt'] as String?;
      if (lca != null && lca.isNotEmpty) {
        at = DateTime.tryParse(lca);
      }
      _addEvent(
        EventChatStreamReadCursorUpdated(
          eventId: eventId,
          userId: uid,
          displayName: dn,
          lastReadMessageId: map['lastReadMessageId'] as String?,
          lastReadMessageCreatedAt: at,
        ),
      );
    }
  }

  void _replayCurrentStatus() {
    if (_controller.isClosed) {
      return;
    }
    // While a handshake is in flight, report reconnecting — not stale disconnected.
    final EventChatConnectionStatus replay =
        _lastStatus == EventChatConnectionStatus.disconnected &&
            (_socket != null && !_socket!.connected)
        ? EventChatConnectionStatus.reconnecting
        : _lastStatus;
    _addEvent(EventChatStreamConnectionChanged(replay));
  }

  void _emitStatus(EventChatConnectionStatus status) {
    if (_lastStatus == status) return;
    _lastStatus = status;
    _syncDisruptionForStatus(status);
    _addEvent(EventChatStreamConnectionChanged(status));
  }

  void _addEvent(EventChatStreamEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  /// Drops misrouted payloads when the server includes an [eventId] that does
  /// not match the room we joined ([_currentEventId]).
  bool _payloadRoomMatches(dynamic raw) {
    final Map<String, dynamic>? map = _asStringKeyedMap(raw);
    if (map == null) {
      return true;
    }
    final Object? eid = map['eventId'];
    if (eid is! String || eid.isEmpty) {
      return true;
    }
    final String? cur = _currentEventId;
    if (cur == null || cur.isEmpty) {
      return false;
    }
    if (eid != cur) {
      AppLog.verbose('[chat:ws] drop payload eventId mismatch room=$cur');
      return false;
    }
    return true;
  }

  bool _messageRoomMatches(EventChatMessage m) {
    final String? cur = _currentEventId;
    if (cur == null || cur.isEmpty) {
      return false;
    }
    if (m.eventId != cur) {
      AppLog.verbose('[chat:ws] drop message eventId mismatch room=$cur');
      return false;
    }
    return true;
  }

  /// Invokes the same path as server `AUTH_FAILED` for unit tests (no socket required).
  @visibleForTesting
  Future<void> handleAuthFailedForTest(String eventId) =>
      _onAuthFailed(eventId);

  /// Applies refresh outcome without opening a socket (unit tests).
  @visibleForTesting
  void applyAuthRefreshOutcomeForTest(String eventId, RefreshOutcome outcome) {
    _applyAuthRefreshOutcome(eventId, outcome);
  }
}
