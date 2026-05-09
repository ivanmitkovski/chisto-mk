import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/network/connectivity_gate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import 'map_site_event.dart';

enum MapRealtimeConnectionState { disconnected, connecting, live, reconnecting }

/// SSE client for map site events: backoff caps at 30s (aligned with API Redis policy).
///
/// Hardening vs naive SSE:
/// - 401 triggers [sessionRefresh] before signing out (same idea as reports Socket.IO).
/// - Heartbeat watchdog: if no bytes for [_watchdogMaxSilence], force-close and retry.
/// - [requestReconnect] for lifecycle / connectivity (closes active stream).
/// - Token rotation while connected aborts the stream so the next attempt uses the new JWT.
class MapRealtimeService {
  MapRealtimeService({
    required AppConfig config,
    required AuthState authState,
    this.sessionRefresh,
    http.Client? httpClient,
  }) : _baseUrl = config.apiBaseUrl.replaceFirst(RegExp(r'/$'), ''),
       _authState = authState,
       _ownsHttpClient = httpClient == null,
       _injectedHttp = httpClient {
    _authState.addListener(_onAuthChanged);
  }

  static const Duration _watchdogInterval = Duration(seconds: 15);
  static const Duration _watchdogMaxSilence = Duration(seconds: 60);

  final String _baseUrl;
  final AuthState _authState;
  final Future<bool> Function()? sessionRefresh;

  final bool _ownsHttpClient;
  /// Non-null only when tests inject a shared [http.Client].
  final http.Client? _injectedHttp;

  final StreamController<MapSiteEvent> _events =
      StreamController<MapSiteEvent>.broadcast();
  final StreamController<MapRealtimeConnectionState> _states =
      StreamController<MapRealtimeConnectionState>.broadcast();

  Stream<MapSiteEvent> get events => _events.stream;
  Stream<MapRealtimeConnectionState> get states => _states.stream;

  bool _disposed = false;
  bool _enabled = false;
  bool _loopRunning = false;
  int _attempt = 0;
  MapRealtimeConnectionState _state = MapRealtimeConnectionState.disconnected;
  String? _lastEventId;

  /// The [http.Client] used for the in-flight SSE attempt (owned or injected).
  http.Client? _activeSseAttemptClient;

  /// Active SSE line subscription (cancel on [requestReconnect] / teardown).
  StreamSubscription<String>? _sseLineSub;

  /// Completes when the active SSE line stream should end (cancel does not call [onDone]).
  Completer<void>? _sseReadCompleter;

  String? _tokenAtConnect;
  DateTime? _lastByteAt;
  Timer? _watchdogTimer;
  bool _abortRequested = false;
  bool _immediateRetryAfterAttempt = false;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _lastConnectivityOnline = true;

  void setActive(bool active) {
    if (_disposed) {
      return;
    }
    _enabled = active;
    if (!active) {
      _stopConnectivityWatch();
      _closeActiveConnection();
      _tokenAtConnect = null;
      _setState(MapRealtimeConnectionState.disconnected);
      return;
    }
    unawaited(_startConnectivityWatchIfNeeded());
    unawaited(_ensureConnected());
  }

  /// Forces the current stream to drop so [setActive] loop reconnects (NAT, ALB, resume).
  void requestReconnect() {
    if (_disposed || !_enabled) {
      return;
    }
    if (_state == MapRealtimeConnectionState.live ||
        _state == MapRealtimeConnectionState.connecting) {
      _setState(MapRealtimeConnectionState.reconnecting);
    }
    _closeActiveConnection();
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _enabled = false;
    _authState.removeListener(_onAuthChanged);
    _stopConnectivityWatch();
    _closeActiveConnection(disposeOnly: true);
    _events.close();
    _states.close();
  }

  void _onAuthChanged() {
    if (_disposed) {
      return;
    }
    if (!_authState.isAuthenticated) {
      _closeActiveConnection();
      _tokenAtConnect = null;
      _setState(MapRealtimeConnectionState.disconnected);
      return;
    }
    final String? token = _authState.accessToken;
    if (token == null || token.isEmpty) {
      return;
    }
    if (_enabled &&
        _tokenAtConnect != null &&
        _tokenAtConnect!.isNotEmpty &&
        _tokenAtConnect != token) {
      requestReconnect();
      return;
    }
    if (_enabled) {
      unawaited(_ensureConnected());
    }
  }

  Future<void> _ensureConnected() async {
    if (_disposed || !_enabled) {
      return;
    }
    if (!_authState.isAuthenticated) {
      return;
    }
    final String? token = _authState.accessToken;
    if (token == null || token.isEmpty) {
      return;
    }
    if (_loopRunning) {
      return;
    }
    _loopRunning = true;
    try {
      await _connectLoop();
    } finally {
      _loopRunning = false;
    }
  }

  Future<void> _connectLoop() async {
    while (!_disposed && _enabled && _authState.isAuthenticated) {
      final String? token = _authState.accessToken;
      if (token == null || token.isEmpty) {
        _setState(MapRealtimeConnectionState.disconnected);
        return;
      }
      _setState(
        _attempt == 0
            ? MapRealtimeConnectionState.connecting
            : MapRealtimeConnectionState.reconnecting,
      );
      try {
        await _connectOnce(token);
      } catch (_) {
        // Retry after backoff when stream fails.
      }
      if (_disposed || !_enabled || !_authState.isAuthenticated) {
        _setState(MapRealtimeConnectionState.disconnected);
        return;
      }
      if (_immediateRetryAfterAttempt) {
        _immediateRetryAfterAttempt = false;
        continue;
      }
      _attempt += 1;
      await Future<void>.delayed(_nextBackoff(_attempt));
    }
  }

  Duration _nextBackoff(int attempt) {
    final int cappedAttempt = attempt.clamp(1, 8);
    final int baseMs = 500 * (1 << (cappedAttempt - 1));
    const int maxMs = 30 * 1000;
    final int ms = math.min(baseMs, maxMs);
    final int jitterMs = (ms * 0.2).round();
    final int random =
        clock.now().microsecondsSinceEpoch % ((jitterMs * 2) + 1);
    final int withJitter = ms - jitterMs + random;
    return Duration(milliseconds: withJitter.clamp(300, maxMs));
  }

  Future<void> _connectOnce(String token) async {
    _abortRequested = false;
    final http.Client attemptClient =
        _ownsHttpClient ? http.Client() : _injectedHttp!;
    _activeSseAttemptClient = attemptClient;

    try {
      final Uri uri = Uri.parse('$_baseUrl/sites/events');
      final http.Request req = http.Request('GET', uri);
      req.headers['Accept'] = 'text/event-stream';
      req.headers['Cache-Control'] = 'no-cache';
      req.headers['Authorization'] = 'Bearer $token';
      if (_lastEventId != null && _lastEventId!.isNotEmpty) {
        req.headers['Last-Event-ID'] = _lastEventId!;
      }

      final http.StreamedResponse res = await attemptClient.send(req);
      if (res.statusCode == 401) {
        try {
          await res.stream.drain<void>();
        } catch (_) {}
        final bool refreshed = await _tryRefreshSession();
        if (refreshed && _authState.isAuthenticated) {
          _attempt = 0;
          _immediateRetryAfterAttempt = true;
          return;
        }
        _authState.setUnauthenticated();
        return;
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        try {
          await res.stream.drain<void>();
        } catch (_) {}
        throw Exception('Map SSE connect failed: ${res.statusCode}');
      }

      _attempt = 0;
      _tokenAtConnect = token;
      _setState(MapRealtimeConnectionState.live);
      _touchLastByteReceived();
      _startWatchdog();

      final Stream<String> lines = res.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      final StringBuffer data = StringBuffer();
      String? currentEventId;

      void flushSseBuffer() {
        if (data.isEmpty) {
          currentEventId = null;
          return;
        }
        final String raw = data.toString();
        data.clear();
        final Object? decoded;
        try {
          decoded = jsonDecode(raw);
        } catch (_) {
          currentEventId = null;
          return;
        }
        if (decoded is! Map<String, dynamic>) {
          currentEventId = null;
          return;
        }
        final MapSiteEvent? event = MapSiteEvent.tryFromJson(decoded);
        if (event != null) {
          if (currentEventId != null && currentEventId!.isNotEmpty) {
            _lastEventId = currentEventId;
          }
          if (!_events.isClosed) {
            _events.add(event);
          }
        }
        currentEventId = null;
      }

      final Completer<void> sseLinesDone = Completer<void>();
      _sseReadCompleter = sseLinesDone;
      _sseLineSub = lines.listen(
        (String line) {
          if (_disposed || !_enabled || !_authState.isAuthenticated) {
            if (!sseLinesDone.isCompleted) {
              sseLinesDone.complete();
            }
            return;
          }
          if (_abortRequested) {
            if (!sseLinesDone.isCompleted) {
              sseLinesDone.complete();
            }
            return;
          }
          _touchLastByteReceived();
          if (line.isEmpty) {
            flushSseBuffer();
            return;
          }
          if (line.startsWith(':')) {
            return;
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
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!sseLinesDone.isCompleted) {
            sseLinesDone.completeError(error, stackTrace);
          }
        },
        onDone: () {
          if (!sseLinesDone.isCompleted) {
            sseLinesDone.complete();
          }
        },
        cancelOnError: true,
      );

      try {
        await sseLinesDone.future;
      } catch (_) {
        // Transport / decode errors: outer loop reconnects.
      } finally {
        await _sseLineSub?.cancel();
        _sseLineSub = null;
      }
    } finally {
      _sseReadCompleter = null;
      _stopWatchdog();
      // Injected [httpClient] is owned by the caller/tests; never close it per attempt.
      if (_ownsHttpClient) {
        try {
          attemptClient.close();
        } catch (_) {}
      }
      if (_activeSseAttemptClient == attemptClient) {
        _activeSseAttemptClient = null;
      }
      if (_abortRequested) {
        _abortRequested = false;
      }
    }
  }

  Future<bool> _tryRefreshSession() async {
    final Future<bool> Function()? refresh = sessionRefresh;
    if (refresh == null) {
      return false;
    }
    try {
      return await refresh();
    } catch (_) {
      return false;
    }
  }

  void _touchLastByteReceived() {
    _lastByteAt = clock.now();
  }

  void _startWatchdog() {
    _stopWatchdog();
    _watchdogTimer = Timer.periodic(_watchdogInterval, (_) {
      if (_disposed || !_enabled) {
        return;
      }
      final DateTime? last = _lastByteAt;
      if (last == null) {
        return;
      }
      if (clock.now().difference(last) > _watchdogMaxSilence) {
        requestReconnect();
      }
    });
  }

  void _stopWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
  }

  void _setState(MapRealtimeConnectionState next) {
    if (_state == next || _disposed) {
      return;
    }
    _state = next;
    if (!_states.isClosed) {
      _states.add(next);
    }
  }

  void _closeActiveConnection({bool disposeOnly = false}) {
    _stopWatchdog();
    _abortRequested = true;
    final Completer<void>? readDone = _sseReadCompleter;
    if (readDone != null && !readDone.isCompleted) {
      readDone.complete();
    }
    final StreamSubscription<String>? lineSub = _sseLineSub;
    _sseLineSub = null;
    unawaited(lineSub?.cancel() ?? Future<void>.value());
    final http.Client? active = _activeSseAttemptClient;
    if (active != null) {
      _activeSseAttemptClient = null;
      if (_ownsHttpClient) {
        try {
          active.close();
        } catch (_) {}
      }
    }
    final http.Client? injected = _injectedHttp;
    if (disposeOnly && !_ownsHttpClient && injected != null) {
      try {
        injected.close();
      } catch (_) {}
    }
  }

  Future<void> _startConnectivityWatchIfNeeded() async {
    if (_connectivitySub != null) {
      return;
    }
    try {
      final List<ConnectivityResult> initial = await ConnectivityGate.check();
      _lastConnectivityOnline = ConnectivityGate.isOnline(initial);
    } catch (_) {
      _lastConnectivityOnline = true;
    }
    _connectivitySub = ConnectivityGate.watch().listen(
      (List<ConnectivityResult> results) {
        if (_disposed || !_enabled) {
          return;
        }
        final bool online = ConnectivityGate.isOnline(results);
        if (!_lastConnectivityOnline && online) {
          requestReconnect();
        }
        _lastConnectivityOnline = online;
      },
      onError: (_) {},
    );
  }

  void _stopConnectivityWatch() {
    unawaited(_connectivitySub?.cancel() ?? Future<void>.value());
    _connectivitySub = null;
  }
}
