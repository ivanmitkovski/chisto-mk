/// Live SSE transport state for event chat (UI banner).
enum EventChatConnectionStatus {
  /// Stream is open or first connection succeeded.
  connected,

  /// Backing off before reconnect or waiting to open SSE.
  reconnecting,

  /// Auth failed or stream ended without reconnect (e.g. logged out).
  disconnected,
}
