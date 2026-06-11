import 'package:chisto_infrastructure/core/network/realtime_socket_transport_policy.dart';

/// Strips REST `/v1` suffix and picks transports suited for the socket host.
String normalizeRealtimeSocketBaseUrl(String raw) {
  final String trimmed = raw.replaceFirst(RegExp(r'/$'), '');
  if (trimmed.endsWith('/v1')) {
    return trimmed.substring(0, trimmed.length - 3);
  }
  return trimmed;
}

/// HTTP (cleartext ALB) uses polling first; HTTPS keeps ws-first policy.
RealtimeSocketTransportPolicy reportsOwnerTransportPolicy(String baseUrl) {
  final Uri? uri = Uri.tryParse(baseUrl);
  if (uri != null && uri.scheme == 'http') {
    return RealtimeSocketTransportPolicy(preferWebSocket: false);
  }
  return RealtimeSocketTransportPolicy(fallbackAfterFailedAttempts: 1);
}
