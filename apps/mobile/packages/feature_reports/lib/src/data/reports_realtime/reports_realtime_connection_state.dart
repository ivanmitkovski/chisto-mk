/// High-level SSE connection state for reports owner stream.
enum ReportsRealtimeConnectionState {
  /// Opening HTTP stream.
  connecting,

  /// Bytes flowing; events may arrive.
  live,

  /// Stream ended or failed; backoff before retry.
  reconnecting,

  /// User signed out or service disposed.
  offline,
}
