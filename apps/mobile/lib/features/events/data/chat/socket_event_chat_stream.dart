import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/logging/app_log.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_connection_status.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_stream_event.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

/// When true (`--dart-define=CHAT_WS_ONLY=true`), use websocket-only (stricter; test after /socket.io reaches the API).
const bool kChatSocketWsOnly =
    bool.fromEnvironment('CHAT_WS_ONLY', defaultValue: false);

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

/// Manages a Socket.IO connection to the chat namespace.
///
/// Produces [EventChatStreamEvent] objects through a broadcast stream,
/// matching the same interface used by the SSE transport so that the
/// repository layer can swap transports transparently.
class SocketEventChatStream {
  SocketEventChatStream({
    required String baseUrl,
    required AuthState authState,
  })  : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
        _authState = authState;

  final String _baseUrl;
  final AuthState _authState;

  sio.Socket? _socket;
  String? _currentEventId;
  bool _authListenerAttached = false;
  String? _tokenAtHandshake;
  final StreamController<EventChatStreamEvent> _controller =
      StreamController<EventChatStreamEvent>.broadcast();

  Stream<EventChatStreamEvent> get stream => _controller.stream;

  EventChatConnectionStatus _lastStatus = EventChatConnectionStatus.disconnected;

  EventChatConnectionStatus get connectionStatus => _lastStatus;

  void connect(String eventId) {
    _currentEventId = eventId;
    _disconnectSocketOnly();
    _ensureAuthListener();

    final String? token = _authState.accessToken;
    if (token == null || token.isEmpty) return;

    // Socket.IO expects an http(s) origin; the client opens ws/wss internally.
    final String origin = '$_baseUrl/chat';
    final String debugHost = Uri.tryParse(_baseUrl)?.host ?? _baseUrl;

    _socket = sio.io(
      origin,
      sio.OptionBuilder()
          // Polling first works more reliably behind ALB/proxies; then upgrades.
          .setTransports(
            kChatSocketWsOnly
                ? <String>['websocket']
                : <String>['polling', 'websocket'],
          )
          // Fresh token on every connect/reconnect (access JWT is short-lived; static
          // setAuth would keep the expired token after proactive refresh).
          .setAuthFn((void Function(Map<dynamic, dynamic> data) submit) {
            final String? t = _authState.accessToken;
            if (t == null || t.isEmpty) {
              submit(<String, dynamic>{});
              return;
            }
            submit(<String, String>{'token': t});
          })
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(30000)
          // Slow TLS / ALB cold path: default 20s can abort before handshake completes.
          .setTimeout(60000)
          .build(),
    );

    _socket!
      ..onConnect((_) {
        AppLog.verbose(
          '[chat:ws] connect host=$debugHost event=$eventId wsOnly=$kChatSocketWsOnly',
        );
        _tokenAtHandshake = _authState.accessToken;
        _emitStatus(EventChatConnectionStatus.connected);
        // Let the namespace handshake finish before joining rooms (pairs with server await join).
        scheduleMicrotask(() {
          final sio.Socket? s = _socket;
          if (s != null) {
            s.emit('join', <String, String>{'eventId': eventId});
          }
        });
      })
      ..onReconnect((_) {
        _tokenAtHandshake = _authState.accessToken;
        _emitStatus(EventChatConnectionStatus.connected);
        scheduleMicrotask(() {
          final sio.Socket? s = _socket;
          if (s != null) {
            s.emit('join', <String, String>{'eventId': eventId});
          }
        });
      })
      ..onReconnectAttempt((_) {
        AppLog.verbose('[chat:ws] reconnectAttempt host=$debugHost event=$eventId');
        _emitStatus(EventChatConnectionStatus.reconnecting);
      })
      ..onConnectError((dynamic data) {
        AppLog.verbose(
          '[chat:ws] connect_error host=$debugHost event=$eventId type=${data.runtimeType}',
        );
        _emitStatus(EventChatConnectionStatus.reconnecting);
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
        _emitStatus(EventChatConnectionStatus.reconnecting);
      })
      ..on('error', (dynamic data) {
        if (data is Map && data['code'] == 'AUTH_FAILED') {
          _disconnectSocketOnly();
          _emitStatus(EventChatConnectionStatus.disconnected);
        }
      })
      ..on('message:created', (dynamic data) {
        final dynamic raw = _unwrapSocketArgs(data);
        if (!_payloadRoomMatches(raw)) {
          return;
        }
        final EventChatMessage? m = _parseMessage(raw);
        if (m != null) {
          if (_messageRoomMatches(m)) {
            _addEvent(EventChatStreamMessageCreated(
              m.withViewer(_authState.userId),
            ));
          }
        } else {
          AppLog.verbose(
            '[chat:ws] message:created parse failed event=$eventId keys=${_debugPayloadKeys(raw)}',
          );
        }
      })
      ..on('message:deleted', (dynamic data) {
        final dynamic raw = _unwrapSocketArgs(data);
        if (!_payloadRoomMatches(raw)) {
          return;
        }
        final String? mid = _str(raw, 'messageId');
        if (mid != null) _addEvent(EventChatStreamMessageDeleted(mid));
      })
      ..on('message:edited', (dynamic data) {
        final dynamic raw = _unwrapSocketArgs(data);
        if (!_payloadRoomMatches(raw)) {
          return;
        }
        final EventChatMessage? m = _parseMessage(raw);
        if (m != null && _messageRoomMatches(m)) {
          _addEvent(EventChatStreamMessageEdited(
            m.withViewer(_authState.userId),
          ));
        }
      })
      ..on('message:pinned', (dynamic data) {
        final dynamic raw = _unwrapSocketArgs(data);
        if (!_payloadRoomMatches(raw)) {
          return;
        }
        final EventChatMessage? m = _parseMessage(raw);
        if (m != null && _messageRoomMatches(m)) {
          _addEvent(EventChatStreamMessagePinned(
            m.withViewer(_authState.userId),
          ));
        }
      })
      ..on('message:unpinned', (dynamic data) {
        final dynamic raw = _unwrapSocketArgs(data);
        if (!_payloadRoomMatches(raw)) {
          return;
        }
        final EventChatMessage? m = _parseMessage(raw);
        if (m != null && _messageRoomMatches(m)) {
          _addEvent(EventChatStreamMessageUnpinned(
            m.withViewer(_authState.userId),
          ));
        }
      })
      ..on('typing:update', (dynamic data) {
        final Map<String, dynamic>? map = _asStringKeyedMap(_unwrapSocketArgs(data));
        if (map == null) return;
        final Object? pe = map['eventId'];
        if (pe is String &&
            pe.isNotEmpty &&
            (_currentEventId == null || pe != _currentEventId)) {
          AppLog.verbose('[chat:ws] drop typing eventId mismatch');
          return;
        }
        final String? uid = map['userId'] as String?;
        final String? dn = map['displayName'] as String?;
        final bool? ty = map['typing'] as bool?;
        if (uid != null && ty != null) {
          final String name = (dn != null && dn.trim().isNotEmpty) ? dn.trim() : '';
          _addEvent(EventChatStreamTypingUpdated(
            eventId: eventId,
            userId: uid,
            displayName: name,
            typing: ty,
          ));
        }
      })
      ..on('read_cursor:updated', (dynamic data) {
        final Map<String, dynamic>? map = _asStringKeyedMap(_unwrapSocketArgs(data));
        if (map == null) return;
        final Object? pe = map['eventId'];
        if (pe is String &&
            pe.isNotEmpty &&
            (_currentEventId == null || pe != _currentEventId)) {
          AppLog.verbose('[chat:ws] drop read_cursor eventId mismatch');
          return;
        }
        final String? uid = map['userId'] as String?;
        final String? dn = map['displayName'] as String?;
        if (uid != null && dn != null) {
          DateTime? at;
          final String? lca = map['lastReadMessageCreatedAt'] as String?;
          if (lca != null && lca.isNotEmpty) at = DateTime.tryParse(lca);
          _addEvent(EventChatStreamReadCursorUpdated(
            eventId: eventId,
            userId: uid,
            displayName: dn,
            lastReadMessageId: map['lastReadMessageId'] as String?,
            lastReadMessageCreatedAt: at,
          ));
        }
      });

    _socket!.connect();
  }

  void emitTyping(String eventId, bool typing) {
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
    _currentEventId = null;
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
      return value.map(
        (Object? k, Object? v) => MapEntry(k.toString(), v),
      );
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

  String? _str(dynamic data, String key) {
    final Map<String, dynamic>? map = _asStringKeyedMap(data);
    if (map == null) return null;
    return map[key] as String?;
  }

  /// JSON from Socket.IO is often `Map<dynamic, dynamic>`; normalize for parsing.
  Map<String, dynamic>? _asStringKeyedMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (Object? k, Object? v) => MapEntry(k.toString(), v),
      );
    }
    return null;
  }

  void _emitStatus(EventChatConnectionStatus status) {
    if (_lastStatus == status) return;
    _lastStatus = status;
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
}
