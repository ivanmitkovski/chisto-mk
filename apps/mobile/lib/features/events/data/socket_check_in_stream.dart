import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

/// Prefer `--dart-define=CHECKIN_WS_ONLY=true` for check-in only; falls back to
/// [CHAT_WS_ONLY] so existing dev scripts keep working.
const bool kCheckInSocketWsOnly = bool.fromEnvironment(
  'CHECKIN_WS_ONLY',
  defaultValue: bool.fromEnvironment('CHAT_WS_ONLY', defaultValue: false),
);

/// Events emitted by [SocketCheckInStream].
sealed class CheckInStreamEvent {
  const CheckInStreamEvent();
}

class CheckInRequestEvent extends CheckInStreamEvent {
  const CheckInRequestEvent({
    required this.pendingId,
    required this.eventId,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.expiresAt,
    this.avatarUrl,
  });

  final String pendingId;
  final String eventId;
  final String userId;
  final String firstName;
  final String lastName;
  final String expiresAt;

  /// Signed profile image URL when the volunteer has an avatar.
  final String? avatarUrl;
}

class CheckInConfirmedEvent extends CheckInStreamEvent {
  const CheckInConfirmedEvent({
    required this.pendingId,
    required this.eventId,
    required this.userId,
    required this.checkedInAt,
    required this.pointsAwarded,
    this.displayName,
  });

  final String pendingId;
  final String eventId;
  final String userId;
  final String checkedInAt;
  final int pointsAwarded;
  final String? displayName;
}

class CheckInRejectedEvent extends CheckInStreamEvent {
  const CheckInRejectedEvent({
    required this.pendingId,
    required this.eventId,
    required this.userId,
  });

  final String pendingId;
  final String eventId;
  final String userId;
}

enum CheckInWsConnectionStatus { disconnected, connecting, connected }

class CheckInConnectionChanged extends CheckInStreamEvent {
  const CheckInConnectionChanged(this.status);
  final CheckInWsConnectionStatus status;
}

/// Socket.IO client for the `/check-in` namespace.
///
/// Mirrors the pattern of [SocketEventChatStream] for the `/chat` namespace.
class SocketCheckInStream {
  SocketCheckInStream({required String baseUrl, required AuthState authState})
    : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
      _authState = authState;

  final String _baseUrl;
  final AuthState _authState;

  sio.Socket? _socket;
  String? _currentEventId;
  bool _authListenerAttached = false;
  String? _tokenAtHandshake;
  int _connectErrorCount = 0;
  static const int _maxConnectErrors = 5;

  final StreamController<CheckInStreamEvent> _controller =
      StreamController<CheckInStreamEvent>.broadcast();

  Stream<CheckInStreamEvent> get stream => _controller.stream;

  CheckInWsConnectionStatus _lastStatus =
      CheckInWsConnectionStatus.disconnected;
  CheckInWsConnectionStatus get connectionStatus => _lastStatus;

  void connect(String eventId) {
    _currentEventId = eventId;
    _disconnectSocketOnly();
    _connectErrorCount = 0;
    _ensureAuthListener();

    final String? token = _authState.accessToken;
    if (token == null || token.isEmpty) return;

    final String origin = '$_baseUrl/check-in';
    final String debugHost = Uri.tryParse(_baseUrl)?.host ?? _baseUrl;

    _socket = sio.io(
      origin,
      sio.OptionBuilder()
          .setTransports(
            kCheckInSocketWsOnly
                ? <String>['websocket']
                : <String>['polling', 'websocket'],
          )
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
          .setReconnectionDelayMax(15000)
          .setTimeout(60000)
          .build(),
    );

    _socket!
      ..onConnect((_) {
        _connectErrorCount = 0;
        if (kDebugMode) {
          debugPrint('[checkin:ws] connect host=$debugHost event=$eventId');
        }
        _tokenAtHandshake = _authState.accessToken;
        _emitStatus(CheckInWsConnectionStatus.connected);
        scheduleMicrotask(() {
          _socket?.emit('join', <String, String>{'eventId': eventId});
        });
      })
      ..onReconnect((_) {
        _tokenAtHandshake = _authState.accessToken;
        _emitStatus(CheckInWsConnectionStatus.connected);
        scheduleMicrotask(() {
          _socket?.emit('join', <String, String>{'eventId': eventId});
        });
      })
      ..onReconnectAttempt((_) {
        _emitStatus(CheckInWsConnectionStatus.connecting);
      })
      ..onConnectError((dynamic data) {
        _connectErrorCount++;
        if (kDebugMode) {
          debugPrint(
            '[checkin:ws] connect_error #$_connectErrorCount host=$debugHost event=$eventId data=$data',
          );
        }
        if (_connectErrorCount >= _maxConnectErrors) {
          if (kDebugMode) {
            debugPrint(
              '[checkin:ws] giving up after $_maxConnectErrors errors',
            );
          }
          _disconnectSocketOnly();
          _emitStatus(CheckInWsConnectionStatus.disconnected);
          return;
        }
        _emitStatus(CheckInWsConnectionStatus.connecting);
      })
      ..onDisconnect((dynamic reason) {
        if (kDebugMode) {
          debugPrint(
            '[checkin:ws] disconnect host=$debugHost event=$eventId reason=$reason',
          );
        }
        _emitStatus(CheckInWsConnectionStatus.connecting);
      })
      ..on('error', (dynamic data) {
        if (data is Map && data['code'] == 'AUTH_FAILED') {
          _disconnectSocketOnly();
          _emitStatus(CheckInWsConnectionStatus.disconnected);
        }
      })
      ..on('checkin:request', (dynamic data) {
        final Map<String, dynamic>? map = _asStringKeyedMap(_unwrap(data));
        if (map == null) return;
        final String? pid = map['pendingId'] as String?;
        final String? eid = map['eventId'] as String?;
        final String? uid = map['userId'] as String?;
        final String? fn = map['firstName'] as String?;
        final String? ln = map['lastName'] as String?;
        final String? exp = map['expiresAt'] as String?;
        final String? av = map['avatarUrl'] as String?;
        final String? avatarUrl = av != null && av.trim().isNotEmpty
            ? av.trim()
            : null;
        if (pid != null &&
            eid != null &&
            uid != null &&
            fn != null &&
            ln != null &&
            exp != null) {
          _addEvent(
            CheckInRequestEvent(
              pendingId: pid,
              eventId: eid,
              userId: uid,
              firstName: fn,
              lastName: ln,
              expiresAt: exp,
              avatarUrl: avatarUrl,
            ),
          );
        }
      })
      ..on('checkin:confirmed', (dynamic data) {
        final Map<String, dynamic>? map = _asStringKeyedMap(_unwrap(data));
        if (map == null) return;
        final String? pid = map['pendingId'] as String?;
        final String? eid = map['eventId'] as String?;
        final String? uid = map['userId'] as String?;
        final String? cat = map['checkedInAt'] as String?;
        final num? pts = map['pointsAwarded'] as num?;
        if (pid != null && eid != null && uid != null && cat != null) {
          _addEvent(
            CheckInConfirmedEvent(
              pendingId: pid,
              eventId: eid,
              userId: uid,
              checkedInAt: cat,
              pointsAwarded: pts?.toInt() ?? 0,
              displayName: map['displayName'] as String?,
            ),
          );
        }
      })
      ..on('checkin:rejected', (dynamic data) {
        final Map<String, dynamic>? map = _asStringKeyedMap(_unwrap(data));
        if (map == null) return;
        final String? pid = map['pendingId'] as String?;
        final String? eid = map['eventId'] as String?;
        final String? uid = map['userId'] as String?;
        if (pid != null && eid != null && uid != null) {
          _addEvent(
            CheckInRejectedEvent(pendingId: pid, eventId: eid, userId: uid),
          );
        }
      });

    _socket!.connect();
  }

  void disconnect() => _disconnectSocketOnly();

  void dispose() {
    if (_authListenerAttached) {
      _authState.removeListener(_onAuthStateChanged);
      _authListenerAttached = false;
    }
    _disconnectSocketOnly();
    _currentEventId = null;
    _controller.close();
  }

  void _ensureAuthListener() {
    if (_authListenerAttached) return;
    _authState.addListener(_onAuthStateChanged);
    _authListenerAttached = true;
  }

  void _onAuthStateChanged() {
    if (_controller.isClosed) return;
    final String? eventId = _currentEventId;
    final String? token = _authState.accessToken;
    if (eventId == null || eventId.isEmpty) return;
    if (token == null || token.isEmpty) {
      _disconnectSocketOnly();
      _emitStatus(CheckInWsConnectionStatus.disconnected);
      return;
    }
    final bool connected = _socket != null && _socket!.connected;
    if (connected && token != _tokenAtHandshake) {
      connect(eventId);
    }
  }

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

  dynamic _unwrap(dynamic data) {
    if (data is List && data.length == 1) return data.first;
    return data;
  }

  Map<String, dynamic>? _asStringKeyedMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((Object? k, Object? v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  void _emitStatus(CheckInWsConnectionStatus status) {
    if (_lastStatus == status) return;
    _lastStatus = status;
    _addEvent(CheckInConnectionChanged(status));
  }

  void _addEvent(CheckInStreamEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }
}
