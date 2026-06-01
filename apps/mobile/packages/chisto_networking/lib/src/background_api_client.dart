import 'package:chisto_core/chisto_core.dart';

import 'package:chisto_networking/src/api_client_config.dart';
import 'package:chisto_networking/src/network/api_client.dart';

/// Creates an [ApiClient] for headless isolates (Workmanager, BG tasks).
///
/// Wires [refreshSession] so background drains can recover from 401s without
/// [AppBootstrap].
ApiClient createBackgroundApiClient({
  required ApiClientConfig config,
  required String? Function() accessToken,
  required Future<RefreshOutcome> Function() refreshSession,
  void Function()? onUnauthorized,
}) {
  final ApiClient client = ApiClient(
    config: config,
    accessToken: accessToken,
    onUnauthorized: onUnauthorized ?? () {},
  );
  client.refreshSession = refreshSession;
  return client;
}
