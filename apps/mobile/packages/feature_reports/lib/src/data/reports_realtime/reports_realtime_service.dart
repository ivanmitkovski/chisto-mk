import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_reports/src/data/reports_realtime/reports_owner_event.dart';
import 'package:feature_reports/src/data/reports_realtime/reports_owner_socket_stream.dart';
import 'package:feature_reports/src/data/reports_realtime/reports_realtime_connection_state.dart';
import 'package:flutter/foundation.dart';

/// Owner-scoped report updates via Socket.IO ([`/reports-owner`](apps/api)).
///
/// REST remains the source of truth; this stream only signals when to refetch or patch UI.
class ReportsRealtimeService {
  ReportsRealtimeService({
    required AppConfig config,
    required AuthState authState,
    Future<RefreshOutcome> Function()? sessionRefresh,
    void Function()? onAuthRejected,
  }) : _transport = ReportsOwnerSocketStream(
         baseUrl: config.apiBaseUrl.replaceFirst(RegExp(r'/$'), ''),
         authState: authState,
         sessionRefresh: sessionRefresh,
         onAuthRejected: onAuthRejected,
       );

  /// Test seam: full Socket.IO reconnect coverage still needs injectable transport in prod.
  @visibleForTesting
  ReportsRealtimeService.withTransport(ReportsOwnerSocketStream transport)
    : _transport = transport;

  final ReportsOwnerSocketStream _transport;

  Stream<ReportsOwnerEvent> get events => _transport.events;

  ValueNotifier<ReportsRealtimeConnectionState?> get connectionState =>
      _transport.connectionState;

  ValueNotifier<int> get reconnectStreakSinceLive =>
      _transport.reconnectStreakSinceLive;

  ValueNotifier<bool> get disruptionVisible => _transport.disruptionVisible;

  ValueNotifier<bool> get hasReachedLive => _transport.hasReachedLive;

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
