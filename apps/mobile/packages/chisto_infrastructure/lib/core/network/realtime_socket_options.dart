import 'package:chisto_infrastructure/core/network/realtime_socket_transport_policy.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

/// Shared Socket.IO client options for citizen-facing realtime namespaces.
class RealtimeSocketOptions {
  RealtimeSocketOptions._();

  static sio.OptionBuilder build({
    required RealtimeSocketTransportPolicy transportPolicy,
    required void Function(void Function(Map<dynamic, dynamic> data) submit)
    authSubmit,
    bool enableReconnection = true,
  }) {
    final sio.OptionBuilder builder = sio.OptionBuilder()
        .setTransports(transportPolicy.currentTransports())
        .setAuthFn(authSubmit)
        .setTimeout(60000);
    if (enableReconnection) {
      builder
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(30000);
    } else {
      builder.disableReconnection();
    }
    return builder;
  }

  static void Function(void Function(Map<dynamic, dynamic> data) submit)
  tokenAuthSubmit(String? Function() readToken) {
    return (void Function(Map<dynamic, dynamic> data) submit) {
      final String? token = readToken();
      if (token == null || token.isEmpty) {
        submit(<String, dynamic>{});
        return;
      }
      submit(<String, String>{'token': token});
    };
  }
}
