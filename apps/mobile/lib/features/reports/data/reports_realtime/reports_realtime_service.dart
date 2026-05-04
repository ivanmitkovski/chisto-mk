import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:flutter/foundation.dart';

import 'reports_owner_event.dart';
import 'reports_owner_socket_stream.dart';
import 'reports_realtime_connection_state.dart';

/// Owner-scoped report updates via Socket.IO ([`/reports-owner`](apps/api)).
///
/// REST remains the source of truth; this stream only signals when to refetch or patch UI.
class ReportsRealtimeService {
  ReportsRealtimeService({
    required AppConfig config,
    required AuthState authState,
    Future<bool> Function()? sessionRefresh,
  }) : _transport = ReportsOwnerSocketStream(
         baseUrl: config.apiBaseUrl.replaceFirst(RegExp(r'/$'), ''),
         authState: authState,
         sessionRefresh: sessionRefresh,
       );

  /// Test seam: full Socket.IO reconnect coverage still needs injectable transport in prod.
  @visibleForTesting
  ReportsRealtimeService.withTransport(ReportsOwnerSocketStream transport)
    : _transport = transport;

  final ReportsOwnerSocketStream _transport;

  Stream<ReportsOwnerEvent> get events => _transport.events;

  ValueNotifier<ReportsRealtimeConnectionState?> get connectionState =>
      _transport.connectionState;

  ValueNotifier<int> get reconnectStreakSinceLive => _transport.reconnectStreakSinceLive;

  Future<void> start() async {
    _transport.start();
  }

  Future<void> stop() async {
    _transport.stop();
  }

  void requestReconnect() {
    _transport.requestReconnect();
  }

  void dispose() {
    _transport.dispose();
  }
}
