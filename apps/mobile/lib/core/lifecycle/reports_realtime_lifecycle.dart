import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';

/// Forces a reports Socket.IO resync after long background (carrier NAT / suspended sockets).
class ReportsRealtimeLifecycle with WidgetsBindingObserver {
  ReportsRealtimeLifecycle();

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
        ServiceLocator.instance.reportsRealtimeService.requestReconnect();
        unawaited(ServiceLocator.instance.reportOutboxCoordinator.scheduleProcess());
      }
    }
  }
}
