import 'package:flutter/widgets.dart';

import 'package:chisto_mobile/core/providers/notifications_providers.dart';
import 'package:chisto_mobile/core/providers/root_container.dart';

/// Forces map SSE resync after long background (carrier NAT / suspended HTTP).
class MapRealtimeLifecycle with WidgetsBindingObserver {
  MapRealtimeLifecycle();

  DateTime? _pausedAt;

  void register() {
    WidgetsBinding.instance.addObserver(this);
  }

  void unregister() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      final DateTime? paused = _pausedAt;
      _pausedAt = null;
      if (paused == null) {
        return;
      }
      if (DateTime.now().difference(paused) > const Duration(seconds: 30)) {
        readRoot(mapRealtimeServiceProvider).requestReconnect();
      }
    }
  }
}
