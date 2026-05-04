import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/observability/chisto_sentry.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

import 'reports_owner_event.dart';
import 'reports_realtime_connection_state.dart';

/// When true (`--dart-define=CHAT_WS_ONLY=true`), websocket-only (same flag as event chat).
const bool kReportsOwnerSocketWsOnly =
    bool.fromEnvironment('CHAT_WS_ONLY', defaultValue: false);

/// Socket.IO client for [`/reports-owner`](apps/api) — owner report events (`report_event`).
class ReportsOwnerSocketStream {
  ReportsOwnerSocketStream({
    required String baseUrl,
    required AuthState authState,
    Future<bool> Function()? sessionRefresh,
  })  : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
        _authState = authState,
        _sessionRefresh = sessionRefresh {
    _authState.addListener(_onAuthChanged);
  }

  final String _baseUrl;
  final AuthState _authState;
  final Future<bool> Function()? _sessionRefresh;

  sio.Socket? _socket;
  String? _tokenAtHandshake;
  bool _enabled = true;
  bool _disposed = false;

  final StreamController<ReportsOwnerEvent> _events =
      StreamController<ReportsOwnerEvent>.broadcast();

  final ValueNotifier<ReportsRealtimeConnectionState?> connectionState =
      ValueNotifier<ReportsRealtimeConnectionState?>(null);

  final ValueNotifier<int> reconnectStreakSinceLive = ValueNotifier<int>(0);

  Stream<ReportsOwnerEvent> get events => _events.stream;

  void _setConnectionState(ReportsRealtimeConnectionState state) {
    if (_disposed) {
      return;
    }
    connectionState.value = state;
  }

  void _onAuthChanged() {
    if (_disposed) {
      return;
    }
    if (!_authState.isAuthenticated) {
      _disconnect();
      reconnectStreakSinceLive.value = 0;
      _setConnectionState(ReportsRealtimeConnectionState.offline);
      return;
    }
    if (!_enabled) {
      return;
    }
    final String? token = _authState.accessToken;
    if (token == null || token.isEmpty) {
      return;
    }
    final bool connected = _socket != null && _socket!.connected;
    if (connected &&
        _tokenAtHandshake != null &&
        _tokenAtHandshake!.isNotEmpty &&
        token != _tokenAtHandshake) {
      connect();
    }
  }

  void start() {
    if (_disposed) {
      return;
    }
    _enabled = true;
    connect();
  }

  void stop() {
    _enabled = false;
    _disconnect();
  }

  void requestReconnect() {
    _setConnectionState(ReportsRealtimeConnectionState.reconnecting);
    reconnectStreakSinceLive.value = reconnectStreakSinceLive.value + 1;
    _disconnect();
    if (_enabled && !_disposed && _authState.isAuthenticated) {
      connect();
    }
  }

  void connect() {
    if (_disposed || !_enabled || !_authState.isAuthenticated) {
      return;
    }
    final String? token = _authState.accessToken;
    if (token == null || token.isEmpty) {
      return;
    }

    _disconnect();
    _setConnectionState(ReportsRealtimeConnectionState.connecting);

    final String origin = '$_baseUrl/reports-owner';
    final String debugHost = Uri.tryParse(_baseUrl)?.host ?? _baseUrl;

    _socket = sio.io(
      origin,
      sio.OptionBuilder()
          .setTransports(
            kReportsOwnerSocketWsOnly
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
          .setReconnectionDelayMax(30000)
          .setTimeout(60000)
          .build(),
    );

    _socket!
      ..onConnect((_) {
        if (kDebugMode) {
          debugPrint('[reports-owner:ws] connect host=$debugHost');
        }
        _tokenAtHandshake = _authState.accessToken;
        reconnectStreakSinceLive.value = 0;
        _setConnectionState(ReportsRealtimeConnectionState.live);
        chistoReportsBreadcrumb('reports_realtime', 'ws_connected');
      })
      ..onReconnect((_) {
        _tokenAtHandshake = _authState.accessToken;
        reconnectStreakSinceLive.value = 0;
        _setConnectionState(ReportsRealtimeConnectionState.live);
      })
      ..onReconnectAttempt((_) {
        if (kDebugMode) {
          debugPrint('[reports-owner:ws] reconnectAttempt host=$debugHost');
        }
        final bool stillConnected = _socket?.connected == true;
        if (stillConnected) {
          return;
        }
        _setConnectionState(ReportsRealtimeConnectionState.reconnecting);
      })
      ..onConnectError((dynamic data) {
        if (kDebugMode) {
          debugPrint(
            '[reports-owner:ws] connect_error host=$debugHost type=${data.runtimeType}',
          );
        }
        if (_socket?.connected == true) {
          return;
        }
        _setConnectionState(ReportsRealtimeConnectionState.reconnecting);
      })
      ..onReconnectError((dynamic data) {
        if (kDebugMode) {
          debugPrint(
            '[reports-owner:ws] reconnect_error host=$debugHost type=${data.runtimeType}',
          );
        }
      })
      ..onDisconnect((_) {
        if (kDebugMode) {
          debugPrint('[reports-owner:ws] disconnect host=$debugHost');
        }
        if (_enabled && !_disposed && _authState.isAuthenticated) {
          reconnectStreakSinceLive.value = reconnectStreakSinceLive.value + 1;
          _setConnectionState(ReportsRealtimeConnectionState.reconnecting);
        }
      })
      ..onError((dynamic err) {
        if (kDebugMode) {
          debugPrint(
            '[reports-owner:ws] engine error host=$debugHost type=${err.runtimeType}',
          );
        }
        if (_socket?.connected == true) {
          return;
        }
        _setConnectionState(ReportsRealtimeConnectionState.reconnecting);
      })
      ..on('error', (dynamic data) {
        if (data is Map && data['code'] == 'AUTH_FAILED') {
          _disconnect();
          _setConnectionState(ReportsRealtimeConnectionState.reconnecting);
          final Future<bool> Function()? refresh = _sessionRefresh;
          if (refresh != null) {
            unawaited(_handleAuthFailedRefresh(refresh));
          } else {
            _setConnectionState(ReportsRealtimeConnectionState.offline);
          }
        }
      })
      ..on('report_event', (dynamic data) {
        final dynamic raw = _unwrapSocketArgs(data);
        final Map<String, dynamic>? map = _asStringKeyedMap(raw);
        if (map == null) {
          return;
        }
        final ReportsOwnerEvent? evt = ReportsOwnerEvent.tryFromJson(map);
        if (evt != null && !_events.isClosed) {
          _events.add(evt);
        }
      });

    _socket!.connect();
  }

  Future<void> _handleAuthFailedRefresh(Future<bool> Function() refresh) async {
    try {
      final bool ok = await refresh();
      if (_disposed || !_enabled) {
        return;
      }
      if (ok && _authState.isAuthenticated) {
        connect();
        return;
      }
    } catch (_) {
      // Fall through to offline.
    }
    if (!_disposed) {
      _setConnectionState(ReportsRealtimeConnectionState.offline);
    }
  }

  void _disconnect() {
    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
    }
    _tokenAtHandshake = null;
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _enabled = false;
    _authState.removeListener(_onAuthChanged);
    _disconnect();
    reconnectStreakSinceLive.dispose();
    connectionState.dispose();
    _events.close();
  }

  static dynamic _unwrapSocketArgs(dynamic data) {
    if (data is List && data.length == 1) {
      return data.first;
    }
    return data;
  }

  static Map<String, dynamic>? _asStringKeyedMap(Object? value) {
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
}
