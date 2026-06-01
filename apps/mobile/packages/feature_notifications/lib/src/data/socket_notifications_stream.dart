import 'dart:async';

import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_notifications/src/domain/models/user_notification.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

/// Real-time notification inbox updates (Instagram/Slack model).
class SocketNotificationsStream {
  SocketNotificationsStream({
    required String baseUrl,
    required AuthState authState,
    Future<RefreshOutcome> Function()? sessionRefresh,
    void Function()? onAuthRejected,
  }) : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
       _authState = authState,
       _sessionRefresh = sessionRefresh,
       _onAuthRejected = onAuthRejected;

  final String _baseUrl;
  final AuthState _authState;
  final Future<RefreshOutcome> Function()? _sessionRefresh;
  final void Function()? _onAuthRejected;

  sio.Socket? _socket;
  String? _tokenAtHandshake;
  bool _authListenerAttached = false;
  bool _refreshInFlight = false;

  final StreamController<int> _unreadController =
      StreamController<int>.broadcast();
  final StreamController<UserNotification> _newItemController =
      StreamController<UserNotification>.broadcast();
  final StreamController<UserNotification> _updatedItemController =
      StreamController<UserNotification>.broadcast();

  Stream<int> get unreadCounts => _unreadController.stream;
  Stream<UserNotification> get newNotifications => _newItemController.stream;
  Stream<UserNotification> get updatedNotifications =>
      _updatedItemController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    if (!_authState.isAuthenticated) return;
    _disconnectSocketOnly();
    _ensureAuthListener();

    final String? token = _authState.accessToken;
    if (token == null || token.isEmpty) return;

    final String origin = '$_baseUrl/notifications';

    _socket = sio.io(
      origin,
      sio.OptionBuilder()
          .setTransports(<String>['websocket', 'polling'])
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
        AppLog.verbose('[notifications:ws] connected');
        _tokenAtHandshake = _authState.accessToken;
      })
      ..onReconnect((_) {
        _tokenAtHandshake = _authState.accessToken;
      })
      ..onDisconnect((_) {
        AppLog.verbose('[notifications:ws] disconnected');
      })
      ..on('notification.new', _onNotificationNew)
      ..on('notification.updated', _onNotificationUpdated)
      ..on('notification.read', _onUnreadPayload)
      ..on('notification.read_all', _onUnreadPayload)
      ..on('notification.archived', _onUnreadPayload)
      ..on('badge.sync', _onUnreadPayload)
      ..on('error', (dynamic data) {
        AppLog.verbose('[notifications:ws] error: $data');
        if (data is Map && data['code'] == 'AUTH_FAILED') {
          _onAuthFailed();
        }
      });

    _socket!.connect();
  }

  Future<void> _onAuthFailed() async {
    if (_refreshInFlight) return;
    final Future<RefreshOutcome> Function()? refresh = _sessionRefresh;
    if (refresh == null) {
      _disconnectSocketOnly();
      return;
    }
    _refreshInFlight = true;
    try {
      final RefreshOutcome outcome = await refresh();
      if (!_authState.isAuthenticated) return;
      switch (outcome) {
        case RefreshOutcome.success:
          // Re-connect with the freshly-issued access token.
          connect();
        case RefreshOutcome.serverRejected:
          _disconnectSocketOnly();
          _onAuthRejected?.call();
        case RefreshOutcome.transient:
          // Stay disconnected; auth-state listener / next reconnect attempt
          // will retry when conditions improve.
          _disconnectSocketOnly();
      }
    } catch (_) {
      // Treat as transient; let upstream lifecycle retry later.
      _disconnectSocketOnly();
    } finally {
      _refreshInFlight = false;
    }
  }

  void _onNotificationUpdated(dynamic data) {
    try {
      final Map<String, dynamic> map = _coerceMap(data);
      final int unread = (map['unreadCount'] as num?)?.toInt() ?? 0;
      _unreadController.add(unread);
      final Object? notif = map['notification'];
      if (notif is Map) {
        final UserNotification item = UserNotification.fromJson(
          Map<String, dynamic>.from(notif),
        );
        _updatedItemController.add(item);
      }
    } catch (e) {
      AppLog.verbose(
        '[notifications:ws] notification.updated parse failed: $e',
      );
    }
  }

  void _onNotificationNew(dynamic data) {
    try {
      final Map<String, dynamic> map = _coerceMap(data);
      final int unread = (map['unreadCount'] as num?)?.toInt() ?? 0;
      _unreadController.add(unread);
      final Object? notif = map['notification'];
      if (notif is Map) {
        final UserNotification item = UserNotification.fromJson(
          Map<String, dynamic>.from(notif),
        );
        _newItemController.add(item);
      }
    } catch (e) {
      AppLog.verbose('[notifications:ws] notification.new parse failed: $e');
    }
  }

  void _onUnreadPayload(dynamic data) {
    try {
      final Map<String, dynamic> map = _coerceMap(data);
      final int unread = (map['unreadCount'] as num?)?.toInt() ?? 0;
      _unreadController.add(unread);
    } catch (e, st) {
      AppLog.warn(
        'notifications:ws unread payload parse failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  Map<String, dynamic> _coerceMap(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is List && data.isNotEmpty && data.first is Map) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    return <String, dynamic>{};
  }

  void _ensureAuthListener() {
    if (_authListenerAttached) return;
    _authListenerAttached = true;
    _authState.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (!_authState.isAuthenticated) {
      disconnect();
      return;
    }
    final String? token = _authState.accessToken;
    if (token == null || token.isEmpty) {
      return;
    }
    if (!isConnected) {
      connect();
      return;
    }
    if (_tokenAtHandshake != null &&
        _tokenAtHandshake!.isNotEmpty &&
        token != _tokenAtHandshake) {
      // Access token rotated — reconnect so the new token is presented.
      connect();
    }
  }

  /// Re-open the socket on app resume (background → foreground). Network
  /// stacks frequently drop idle TCP connections; this avoids stale state.
  void resume() {
    if (!_authState.isAuthenticated) return;
    if (!isConnected) {
      connect();
    }
  }

  void disconnect() {
    _authState.removeListener(_onAuthChanged);
    _authListenerAttached = false;
    _disconnectSocketOnly();
  }

  void _disconnectSocketOnly() {
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _unreadController.close();
    _newItemController.close();
    _updatedItemController.close();
  }

  @visibleForTesting
  void dispatchNotificationNewForTest(dynamic data) => _onNotificationNew(data);

  @visibleForTesting
  void dispatchNotificationUpdatedForTest(dynamic data) =>
      _onNotificationUpdated(data);

  @visibleForTesting
  void dispatchUnreadPayloadForTest(dynamic data) => _onUnreadPayload(data);

  @visibleForTesting
  Future<void> handleAuthFailedForTest() => _onAuthFailed();
}
