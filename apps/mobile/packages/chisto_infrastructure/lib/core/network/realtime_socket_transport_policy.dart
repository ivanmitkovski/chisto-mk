/// Transport selection for Socket.IO realtime clients (reports-owner, chat, …).
///
/// Prefers WebSocket-only to avoid Engine.IO polling session splits behind ALBs
/// during ECS rollovers. Falls back to polling+websocket after repeated failures.
class RealtimeSocketTransportPolicy {
  RealtimeSocketTransportPolicy({
    this.preferWebSocket = kRealtimePreferWebSocket,
    this.wsOnly = kRealtimeWsOnly,
    this.fallbackAfterFailedAttempts = 2,
  });

  /// When true (default), connect with `websocket` only until fallback triggers.
  static const bool kRealtimePreferWebSocket = bool.fromEnvironment(
    'REALTIME_PREFER_WEBSOCKET',
    defaultValue: true,
  );

  /// When true, never fall back to HTTP long-polling (same flag as event chat).
  static const bool kRealtimeWsOnly = bool.fromEnvironment(
    'CHAT_WS_ONLY',
    defaultValue: false,
  );

  final bool preferWebSocket;
  final bool wsOnly;
  final int fallbackAfterFailedAttempts;

  int _failedConnectAttempts = 0;
  bool _usingPollingFallback = false;

  /// Ordered Engine.IO transports for the next socket instance.
  List<String> currentTransports() {
    if (wsOnly) {
      return const <String>['websocket'];
    }
    if (preferWebSocket && !_usingPollingFallback) {
      return const <String>['websocket'];
    }
    return const <String>['polling', 'websocket'];
  }

  String describeTransports() => currentTransports().join(',');

  bool get usingPollingFallback => _usingPollingFallback;

  /// Call when the socket reaches a connected state.
  void recordConnectSuccess() {
    _failedConnectAttempts = 0;
    _usingPollingFallback = false;
  }

  /// Call on handshake/connect errors before deciding to recreate the socket.
  ///
  /// Returns true when transports changed and the caller should open a new socket.
  bool recordConnectFailure() {
    _failedConnectAttempts++;
    if (wsOnly || !preferWebSocket || _usingPollingFallback) {
      return false;
    }
    if (_failedConnectAttempts >= fallbackAfterFailedAttempts) {
      _usingPollingFallback = true;
      return true;
    }
    return false;
  }

  void reset() {
    _failedConnectAttempts = 0;
    _usingPollingFallback = false;
  }
}
