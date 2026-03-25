import 'dart:async';
import 'dart:convert';

import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:http/http.dart' as http;

import 'reports_owner_event.dart';

class ReportsRealtimeService {
  ReportsRealtimeService({
    required AppConfig config,
    required AuthState authState,
    http.Client? httpClient,
  })  : _baseUrl = config.apiBaseUrl.replaceFirst(RegExp(r'/$'), ''),
        _authState = authState,
        _http = httpClient ?? http.Client() {
    _authState.addListener(_onAuthChanged);
  }

  final String _baseUrl;
  final AuthState _authState;
  final http.Client _http;

  final StreamController<ReportsOwnerEvent> _events =
      StreamController<ReportsOwnerEvent>.broadcast();

  Stream<ReportsOwnerEvent> get events => _events.stream;

  bool _enabled = true;
  bool _connecting = false;
  bool _disposed = false;
  int _attempt = 0;

  Future<void> start() async {
    if (_disposed) return;
    _enabled = true;
    await _ensureConnected();
  }

  Future<void> stop() async {
    _enabled = false;
    // Connection is managed via loop; disabling prevents reconnect attempts.
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _enabled = false;
    _authState.removeListener(_onAuthChanged);
    _http.close();
    _events.close();
  }

  void _onAuthChanged() {
    if (_disposed) return;
    // If auth flips to authenticated, connect; if unauthenticated, stop reconnects.
    unawaited(_ensureConnected());
  }

  Future<void> _ensureConnected() async {
    if (_disposed || !_enabled) return;
    if (_connecting) return;
    if (!_authState.isAuthenticated) return;
    final String? token = _authState.accessToken;
    if (token == null || token.isEmpty) return;
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
      if (token == null || token.isEmpty) return;

      try {
        await _connectOnce(token);
        // If the stream ends normally, we'll retry with backoff.
      } catch (_) {
        // Swallow: we backoff and retry unless disabled/disposed/unauthenticated.
      }

      if (_disposed || !_enabled || !_authState.isAuthenticated) return;

      _attempt += 1;
      final Duration delay = _nextBackoff(_attempt);
      await Future<void>.delayed(delay);
    }
  }

  static Duration _nextBackoff(int attempt) {
    // Exponential backoff with cap and jitter.
    final int cappedAttempt = attempt.clamp(1, 8);
    final int baseMs = 500 * (1 << (cappedAttempt - 1)); // 0.5s, 1s, 2s, ...
    final int capMs = 30 * 1000;
    final int ms = baseMs > capMs ? capMs : baseMs;
    final int jitter = (ms * 0.2).round();
    final int jittered = ms - jitter + (DateTime.now().microsecondsSinceEpoch % (jitter * 2 + 1));
    return Duration(milliseconds: jittered.clamp(250, capMs));
  }

  Future<void> _connectOnce(String token) async {
    final Uri uri = Uri.parse('$_baseUrl/reports/events');
    final http.Request req = http.Request('GET', uri);
    req.headers['Accept'] = 'text/event-stream';
    req.headers['Cache-Control'] = 'no-cache';
    req.headers['Authorization'] = 'Bearer $token';

    final http.StreamedResponse res = await _http.send(req);
    if (res.statusCode == 401) {
      _authState.setUnauthenticated();
      return;
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('SSE connect failed: ${res.statusCode}');
    }

    _attempt = 0;

    final Stream<String> lines = res.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    String? eventType;
    final StringBuffer data = StringBuffer();
    String? id;

    Future<void> dispatch() async {
      if (data.isEmpty) {
        eventType = null;
        id = null;
        return;
      }
      final String raw = data.toString();
      data.clear();

      // Heartbeat or comment-only events will be non-JSON; ignore quietly.
      final Object? decoded;
      try {
        decoded = jsonDecode(raw);
      } catch (_) {
        eventType = null;
        id = null;
        return;
      }
      if (decoded is! Map<String, dynamic>) {
        eventType = null;
        id = null;
        return;
      }

      final ReportsOwnerEvent? evt = ReportsOwnerEvent.tryFromJson(decoded);
      if (evt != null) {
        _events.add(evt);
      } else {
        // If schema changes, we can still treat it as a generic change by best-effort fields.
        final Object? reportId = decoded['reportId'];
        final Object? ownerId = decoded['ownerId'];
        final Object? occurredAtMs = decoded['occurredAtMs'];
        if (reportId is String &&
            ownerId is String &&
            occurredAtMs is num &&
            id is String &&
            eventType is String) {
          _events.add(
            ReportsOwnerEvent(
              eventId: id!,
              type: eventType!,
              ownerId: ownerId,
              reportId: reportId,
              occurredAtMs: occurredAtMs.toInt(),
              mutationKind: 'updated',
            ),
          );
        }
      }

      eventType = null;
      id = null;
    }

    await for (final String line in lines) {
      if (_disposed || !_enabled || !_authState.isAuthenticated) return;

      if (line.isEmpty) {
        await dispatch();
        continue;
      }

      if (line.startsWith(':')) {
        // Comment line; ignore.
        continue;
      }

      final int idx = line.indexOf(':');
      final String field = idx == -1 ? line : line.substring(0, idx);
      String value = idx == -1 ? '' : line.substring(idx + 1);
      if (value.startsWith(' ')) value = value.substring(1);

      switch (field) {
        case 'event':
          eventType = value;
          break;
        case 'data':
          if (data.isNotEmpty) data.writeln();
          data.write(value);
          break;
        case 'id':
          id = value;
          break;
        default:
          break;
      }
    }
  }
}

