import 'dart:async';
import 'dart:math' as math;

import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/network/connectivity_gate.dart';
import 'package:chisto_infrastructure/core/network/realtime_disruption_signal.dart';
import 'package:chisto_infrastructure/core/network/realtime_socket_base_url.dart';
import 'package:chisto_infrastructure/core/network/realtime_socket_options.dart';
import 'package:chisto_infrastructure/core/network/realtime_socket_transport_policy.dart';
import 'package:chisto_infrastructure/core/observability/chisto_sentry.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_reports/src/data/reports_realtime/reports_owner_event.dart';
import 'package:feature_reports/src/data/reports_realtime/reports_realtime_connection_state.dart';
import 'package:flutter/foundation.dart' show ValueNotifier, visibleForTesting;
import 'package:socket_io_client/socket_io_client.dart' as sio;

/// When true (`--dart-define=CHAT_WS_ONLY=true`), websocket-only (same flag as event chat).
@Deprecated('Use RealtimeSocketTransportPolicy.kRealtimeWsOnly')
const bool kReportsOwnerSocketWsOnly = RealtimeSocketTransportPolicy.kRealtimeWsOnly;

bool _reportsSocketNeedsReconnectForNewToken({
  required bool socketConnected,
  required String? newAccessToken,
  required String? tokenAtHandshake,
}) {
  return socketConnected &&
      newAccessToken != null &&
      newAccessToken.isNotEmpty &&
      newAccessToken != tokenAtHandshake;
}

/// Socket.IO client for [`/reports-owner`](apps/api) — owner report events (`report_event`).
class ReportsOwnerSocketStream {
  ReportsOwnerSocketStream({
    required String baseUrl,
    required AuthState authState,
    Future<RefreshOutcome> Function()? sessionRefresh,
    void Function()? onAuthRejected,
    RealtimeSocketTransportPolicy? transportPolicy,
    RealtimeDisruptionSignal? disruptionSignal,
    Duration offlineEscalationAfter = const Duration(seconds: 15),
    int maxLoopAttemptsBeforeOffline = 6,
  }) : _baseUrl = normalizeRealtimeSocketBaseUrl(baseUrl),
       _authState = authState,
       _sessionRefresh = sessionRefresh,
       _onAuthRejected = onAuthRejected,
       _offlineEscalationAfter = offlineEscalationAfter,
       _maxLoopAttemptsBeforeOffline = maxLoopAttemptsBeforeOffline,
       _transportPolicy =
           transportPolicy ?? reportsOwnerTransportPolicy(baseUrl) {
    _disruption =
        disruptionSignal ??
        RealtimeDisruptionSignal(
          channel: 'reports-owner',
          resolveHost: () => Uri.tryParse(_baseUrl)?.host ?? _baseUrl,
          resolveTransports: _transportPolicy.describeTransports,
        );
    _authState.addListener(_onAuthChanged);
  }

  final String _baseUrl;
  final AuthState _authState;
  final Future<RefreshOutcome> Function()? _sessionRefresh;
  final void Function()? _onAuthRejected;
  final RealtimeSocketTransportPolicy _transportPolicy;
  final Duration _offlineEscalationAfter;
  final int _maxLoopAttemptsBeforeOffline;
  late final RealtimeDisruptionSignal _disruption;

  sio.Socket? _socket;
  String? _tokenAtHandshake;
  bool _enabled = false;
  bool _disposed = false;
  bool _loopRunning = false;
  bool _abortLoop = false;
  int _loopAttempt = 0;

  /// When true, [_ensureConnected] is a no-op (unit tests only).
  @visibleForTesting
  bool connectDisabledForTest = false;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _connectivityReconnectDebounce;
  Timer? _offlineEscalationTimer;

  final StreamController<ReportsOwnerEvent> _events =
      StreamController<ReportsOwnerEvent>.broadcast();

  late final Stream<ReportsOwnerEvent> _eventsStream = _events.stream;

  final ValueNotifier<ReportsRealtimeConnectionState?> connectionState =
      ValueNotifier<ReportsRealtimeConnectionState?>(null);

  final ValueNotifier<int> reconnectStreakSinceLive = ValueNotifier<int>(0);

  /// True after the server ack [`reports_owner.ready`] or first [`report_event`].
  final ValueNotifier<bool> hasReachedLive = ValueNotifier<bool>(false);

  ValueNotifier<bool> get disruptionVisible => _disruption.visible;

  Stream<ReportsOwnerEvent> get events => _eventsStream;

  String get _debugHost => Uri.tryParse(_baseUrl)?.host ?? _baseUrl;

  void _setConnectionState(ReportsRealtimeConnectionState state) {
    if (_disposed) {
      return;
    }
    connectionState.value = state;
    switch (state) {
      case ReportsRealtimeConnectionState.live:
        _disruption.setLive(isLive: true);
        _cancelOfflineEscalation();
      case ReportsRealtimeConnectionState.offline:
        _disruption.setLive(isLive: true);
        _disruption.visible.value = false;
        _cancelOfflineEscalation();
      case ReportsRealtimeConnectionState.connecting:
        _disruption.setLive(isLive: false);
      case ReportsRealtimeConnectionState.reconnecting:
        _disruption.setLive(isLive: false);
        _maybeScheduleOfflineEscalation();
    }
  }

  void _markLive() {
    _transportPolicy.recordConnectSuccess();
    _tokenAtHandshake = _authState.accessToken;
    reconnectStreakSinceLive.value = 0;
    _loopAttempt = 0;
    hasReachedLive.value = true;
    _setConnectionState(ReportsRealtimeConnectionState.live);
    chistoReportsBreadcrumb('reports_realtime', 'ws_connected');
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    if (_disposed || !_authState.isAuthenticated || !_enabled) {
      return;
    }
    if (!ConnectivityGate.isOnline(results)) {
      return;
    }
    if (connectionState.value == ReportsRealtimeConnectionState.live) {
      return;
    }
    _scheduleConnectivityReconnect();
  }

  void _ensureConnectivitySubscription() {
    if (_disposed || _connectivitySub != null) {
      return;
    }
    _connectivitySub = ConnectivityGate.watch().listen(_onConnectivityChanged);
  }

  void _scheduleConnectivityReconnect() {
    if (_disposed || !_enabled || !_authState.isAuthenticated) {
      return;
    }
    if (connectionState.value == ReportsRealtimeConnectionState.offline) {
      return;
    }
    _connectivityReconnectDebounce?.cancel();
    _connectivityReconnectDebounce = Timer(
      const Duration(milliseconds: 600),
      () {
        _connectivityReconnectDebounce = null;
        if (_disposed || !_enabled || !_authState.isAuthenticated) {
          return;
        }
        unawaited(_ensureConnected());
      },
    );
  }

  void _onAuthChanged() {
    if (_disposed) {
      return;
    }
    if (!_authState.isAuthenticated) {
      _stopInternal(clearLive: true);
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
    if (_reportsSocketNeedsReconnectForNewToken(
      socketConnected: connected,
      newAccessToken: token,
      tokenAtHandshake: _tokenAtHandshake,
    )) {
      requestReconnect();
    }
  }

  void start() {
    if (_disposed) {
      return;
    }
    _enabled = true;
    _ensureConnectivitySubscription();
    unawaited(_ensureConnected());
  }

  /// Lifecycle alias for [start] (realtime client shape guard).
  void connect() => start();

  void stop() {
    _stopInternal(clearLive: false);
  }

  void _stopInternal({required bool clearLive}) {
    _enabled = false;
    _abortLoop = true;
    _cancelOfflineEscalation();
    _disconnect();
    if (clearLive) {
      hasReachedLive.value = false;
      reconnectStreakSinceLive.value = 0;
      _setConnectionState(ReportsRealtimeConnectionState.offline);
    }
  }

  void requestReconnect() {
    if (_disposed) {
      return;
    }
    _cancelOfflineEscalation();
    _transportPolicy.reset();
    reconnectStreakSinceLive.value = 0;
    _loopAttempt = 0;
    _abortLoop = false;
    _disconnect();
    _enabled = true;
    connectionState.value = ReportsRealtimeConnectionState.connecting;
    unawaited(_ensureConnected());
  }

  Future<void> _ensureConnected() async {
    if (_disposed || !_enabled || !_authState.isAuthenticated) {
      return;
    }
    if (connectDisabledForTest) {
      return;
    }
    if (_loopRunning) {
      return;
    }
    if (connectionState.value == ReportsRealtimeConnectionState.offline) {
      return;
    }
    _loopRunning = true;
    _abortLoop = false;
    try {
      await _connectLoop();
    } finally {
      _loopRunning = false;
    }
  }

  Future<void> _connectLoop() async {
    while (!_disposed &&
        _enabled &&
        _authState.isAuthenticated &&
        !_abortLoop &&
        connectionState.value != ReportsRealtimeConnectionState.offline) {
      final String? token = _authState.accessToken;
      if (token == null || token.isEmpty) {
        return;
      }

      _setConnectionState(
        _loopAttempt == 0
            ? ReportsRealtimeConnectionState.connecting
            : ReportsRealtimeConnectionState.reconnecting,
      );

      try {
        await _connectOnce(token);
      } catch (err) {
        AppLog.verbose(
          '[reports-owner:ws] connect attempt failed host=$_debugHost '
          'attempt=$_loopAttempt type=${err.runtimeType}',
        );
        if (_transportPolicy.recordConnectFailure()) {
          AppLog.warn(
            '[reports-owner:ws] falling back to polling+websocket host=$_debugHost',
            category: 'realtime',
          );
        }
      }

      if (_disposed || !_enabled || !_authState.isAuthenticated || _abortLoop) {
        return;
      }

      if (connectionState.value == ReportsRealtimeConnectionState.live) {
        return;
      }

      _loopAttempt++;
      reconnectStreakSinceLive.value = reconnectStreakSinceLive.value + 1;

      if (hasReachedLive.value &&
          _loopAttempt >= _maxLoopAttemptsBeforeOffline) {
        _escalateToOffline();
        return;
      }

      await Future<void>.delayed(_nextBackoff(_loopAttempt));
    }
  }

  Duration _nextBackoff(int attempt) {
    final int capped = attempt.clamp(1, 8);
    final int baseMs = 500 * (1 << (capped - 1));
    const int maxMs = 30 * 1000;
    final int ms = math.min(baseMs, maxMs);
    return Duration(milliseconds: ms);
  }

  Future<void> _connectOnce(String token) async {
    _disconnect();

    final String origin = '$_baseUrl/reports-owner';
    final String debugHost = _debugHost;
    final List<String> transports = _transportPolicy.currentTransports();

    AppLog.verbose(
      '[reports-owner:ws] connect host=$debugHost transports=${transports.join(",")}',
    );

    final Completer<void> readyCompleter = Completer<void>();
    final Completer<void> disconnectCompleter = Completer<void>();
    var liveMarked = false;

    void markLiveOnce() {
      if (liveMarked || _disposed) {
        return;
      }
      liveMarked = true;
      _markLive();
      if (!readyCompleter.isCompleted) {
        readyCompleter.complete();
      }
    }

    _socket = sio.io(
      origin,
      RealtimeSocketOptions.build(
        transportPolicy: _transportPolicy,
        enableReconnection: false,
        authSubmit: RealtimeSocketOptions.tokenAuthSubmit(
          () => _authState.accessToken,
        ),
      ).build(),
    );

    _socket!
      ..onConnect((_) {
        AppLog.verbose('[reports-owner:ws] transport connected host=$debugHost');
      })
      ..onConnectError((dynamic data) {
        AppLog.verbose(
          '[reports-owner:ws] connect_error host=$debugHost type=${data.runtimeType}',
        );
        if (!readyCompleter.isCompleted) {
          readyCompleter.completeError((data as Object?) ?? 'connect_error');
        }
      })
      ..onDisconnect((_) {
        AppLog.verbose('[reports-owner:ws] disconnect host=$debugHost');
        if (!disconnectCompleter.isCompleted) {
          disconnectCompleter.complete();
        }
        if (_enabled && !_disposed && _authState.isAuthenticated) {
          if (connectionState.value == ReportsRealtimeConnectionState.live) {
            _setConnectionState(ReportsRealtimeConnectionState.reconnecting);
          }
        }
      })
      ..on('reports_owner.ready', (dynamic data) {
        AppLog.verbose('[reports-owner:ws] ready host=$debugHost');
        markLiveOnce();
      })
      ..on('error', (dynamic data) {
        if (data is Map && data['code'] == 'AUTH_FAILED') {
          if (!readyCompleter.isCompleted) {
            readyCompleter.completeError('AUTH_FAILED');
          }
          unawaited(_handleAuthFailedAfterReadyFailure());
        }
      })
      ..on('report_event', (dynamic data) {
        markLiveOnce();
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

    try {
      await readyCompleter.future.timeout(const Duration(seconds: 60));
    } catch (err) {
      _disconnect();
      if (err == 'AUTH_FAILED') {
        return;
      }
      rethrow;
    }

    if (_disposed || !_enabled) {
      return;
    }

    await disconnectCompleter.future;
  }

  Future<void> _handleAuthFailedAfterReadyFailure() async {
    _disconnect();
    final Future<RefreshOutcome> Function()? refresh = _sessionRefresh;
    if (refresh == null) {
      _setConnectionState(ReportsRealtimeConnectionState.offline);
      return;
    }
    _setConnectionState(ReportsRealtimeConnectionState.reconnecting);
    try {
      final RefreshOutcome outcome = await refresh();
      if (_disposed || !_enabled) {
        return;
      }
      switch (outcome) {
        case RefreshOutcome.success:
          if (_authState.isAuthenticated) {
            _loopAttempt = 0;
            unawaited(_ensureConnected());
          } else {
            _setConnectionState(ReportsRealtimeConnectionState.offline);
          }
        case RefreshOutcome.serverRejected:
          _setConnectionState(ReportsRealtimeConnectionState.offline);
          _onAuthRejected?.call();
        case RefreshOutcome.transient:
          _setConnectionState(ReportsRealtimeConnectionState.reconnecting);
      }
    } catch (_) {
      if (!_disposed) {
        _setConnectionState(ReportsRealtimeConnectionState.reconnecting);
      }
    }
  }

  void _maybeScheduleOfflineEscalation() {
    if (_disposed || !_enabled || !hasReachedLive.value) {
      return;
    }
    if (connectionState.value == ReportsRealtimeConnectionState.offline) {
      return;
    }
    if (_offlineEscalationTimer?.isActive ?? false) {
      return;
    }
    _offlineEscalationTimer = Timer(_offlineEscalationAfter, _escalateToOffline);
  }

  void _escalateToOffline() {
    if (_disposed || !_enabled) {
      return;
    }
    if (connectionState.value == ReportsRealtimeConnectionState.live) {
      return;
    }
    AppLog.warn(
      '[reports-owner:ws] escalating to offline host=$_debugHost '
      'attempts=$_loopAttempt',
      category: 'realtime',
    );
    _abortLoop = true;
    _cancelOfflineEscalation();
    _disconnect();
    reconnectStreakSinceLive.value = 0;
    _setConnectionState(ReportsRealtimeConnectionState.offline);
  }

  void _cancelOfflineEscalation() {
    _offlineEscalationTimer?.cancel();
    _offlineEscalationTimer = null;
  }

  void _disconnect() {
    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
    }
    _tokenAtHandshake = null;
  }

  /// Test seam: enter reconnecting and schedule offline escalation timers.
  @visibleForTesting
  void enterReconnectingForTest() {
    _enabled = true;
    _setConnectionState(ReportsRealtimeConnectionState.reconnecting);
  }

  /// Test seam: simulate server ready ack without a socket.
  @visibleForTesting
  void markLiveForTest() {
    _markLive();
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _abortLoop = true;
    _connectivityReconnectDebounce?.cancel();
    _connectivityReconnectDebounce = null;
    _cancelOfflineEscalation();
    unawaited(_connectivitySub?.cancel() ?? Future<void>.value());
    _connectivitySub = null;
    _authState.removeListener(_onAuthChanged);
    _disconnect();
    _transportPolicy.reset();
    reconnectStreakSinceLive.dispose();
    hasReachedLive.dispose();
    connectionState.dispose();
    _disruption.dispose();
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
      return value.map((Object? k, Object? v) => MapEntry(k.toString(), v));
    }
    return null;
  }
}
