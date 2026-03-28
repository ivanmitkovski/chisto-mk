import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:http/http.dart' as http;

import 'map_site_event.dart';

enum MapRealtimeConnectionState { disconnected, connecting, live, reconnecting }

/// SSE client: exponential backoff caps at 30s (aligned with API Redis resubscribe policy).
class MapRealtimeService {
  MapRealtimeService({
    required AppConfig config,
    required AuthState authState,
    http.Client? httpClient,
  }) : _baseUrl = config.apiBaseUrl.replaceFirst(RegExp(r'/$'), ''),
       _authState = authState,
       _ownsHttpClient = httpClient == null,
       _http = httpClient ?? http.Client() {
    _authState.addListener(_onAuthChanged);
  }

  final String _baseUrl;
  final AuthState _authState;
  final bool _ownsHttpClient;
  http.Client _http;

  final StreamController<MapSiteEvent> _events =
      StreamController<MapSiteEvent>.broadcast();
  final StreamController<MapRealtimeConnectionState> _states =
      StreamController<MapRealtimeConnectionState>.broadcast();

  Stream<MapSiteEvent> get events => _events.stream;
  Stream<MapRealtimeConnectionState> get states => _states.stream;

  bool _disposed = false;
  bool _enabled = false;
  bool _connecting = false;
  int _attempt = 0;
  MapRealtimeConnectionState _state = MapRealtimeConnectionState.disconnected;
  String? _lastEventId;

  void setActive(bool active) {
    if (_disposed) {
      return;
    }
    _enabled = active;
    if (!active) {
      _closeActiveConnection();
      _setState(MapRealtimeConnectionState.disconnected);
      return;
    }
    unawaited(_ensureConnected());
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _enabled = false;
    _authState.removeListener(_onAuthChanged);
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
      _setState(MapRealtimeConnectionState.disconnected);
      return;
    }
    if (_enabled) {
      unawaited(_ensureConnected());
    }
  }

  Future<void> _ensureConnected() async {
    if (_disposed || !_enabled || _connecting) {
      return;
    }
    if (!_authState.isAuthenticated) {
      return;
    }
    final String? token = _authState.accessToken;
    if (token == null || token.isEmpty) {
      return;
    }
    _connecting = true;
    try {
      await _connectLoop();
    } finally {
      _connecting = false;
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
        DateTime.now().microsecondsSinceEpoch % ((jitterMs * 2) + 1);
    final int withJitter = ms - jitterMs + random;
    return Duration(milliseconds: withJitter.clamp(300, maxMs));
  }

  Future<void> _connectOnce(String token) async {
    final Uri uri = Uri.parse('$_baseUrl/sites/events');
    final http.Request req = http.Request('GET', uri);
    req.headers['Accept'] = 'text/event-stream';
    req.headers['Cache-Control'] = 'no-cache';
    req.headers['Authorization'] = 'Bearer $token';
    if (_lastEventId != null && _lastEventId!.isNotEmpty) {
      req.headers['Last-Event-ID'] = _lastEventId!;
    }

    final http.StreamedResponse res = await _http.send(req);
    if (res.statusCode == 401) {
      _closeActiveConnection();
      _authState.setUnauthenticated();
      return;
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Map SSE connect failed: ${res.statusCode}');
    }

    _attempt = 0;
    _setState(MapRealtimeConnectionState.live);

    final Stream<String> lines = res.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    final StringBuffer data = StringBuffer();
    String? currentEventId;

    Future<void> dispatch() async {
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
        return;
      }
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      final MapSiteEvent? event = MapSiteEvent.tryFromJson(decoded);
      if (event != null) {
        if (currentEventId != null && currentEventId!.isNotEmpty) {
          _lastEventId = currentEventId;
        }
        _events.add(event);
      }
      currentEventId = null;
    }

    await for (final String line in lines) {
      if (_disposed || !_enabled || !_authState.isAuthenticated) {
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

  void _setState(MapRealtimeConnectionState next) {
    if (_state == next || _disposed) {
      return;
    }
    _state = next;
    _states.add(next);
  }

  void _closeActiveConnection({bool disposeOnly = false}) {
    if (!_ownsHttpClient) {
      if (disposeOnly) {
        _http.close();
      }
      return;
    }
    _http.close();
    if (!_disposed && !disposeOnly) {
      _http = http.Client();
    }
  }
}
